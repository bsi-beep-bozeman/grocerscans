"""SOURCE ONLY: requires separately approved R03 target and provisioned fixtures.

Standard library only. No service-role credentials, fixture provisioning, target
startup, migration application or cleanup is performed by this test runner.
It intentionally changes PIN attempt/session state on ONE approved synthetic kiosk.
Never run against the historical empty disposable baseline without provisioning.
"""
import argparse
import concurrent.futures
import json
import os
import time
import urllib.error
import urllib.request


BASE = "http://127.0.0.1:55321"


def request(path, payload, token=None):
    headers = {"apikey": os.environ["S2A_ANON_KEY"], "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read(262145)
        if len(raw) > 262144:
            raise RuntimeError("Oversized synthetic response")
        return json.loads(raw)
    except (urllib.error.URLError, ValueError) as error:
        # Do not echo request/response payloads, URLs with secrets, or exception text.
        raise RuntimeError("Synthetic API request failed") from None


def login():
    response = request("/auth/v1/token?grant_type=password", {
        "email": os.environ["S2A_DEVICE_EMAIL"],
        "password": os.environ["S2A_DEVICE_PASSWORD"],
    })
    return response["access_token"]


def check(condition, label):
    if not condition:
        raise RuntimeError(label)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute-approved-r03", action="store_true")
    parser.add_argument("--wait-for-expiry", action="store_true")
    args = parser.parse_args()
    if not args.execute_approved_r03:
        parser.error("Explicit R03 approval and --execute-approved-r03 are required")
    for field in ("S2A_ANON_KEY", "S2A_DEVICE_EMAIL", "S2A_DEVICE_PASSWORD", "S2A_VALID_SYNTHETIC_PIN",
                  "S2A_EXPECTED_ORG_ID", "S2A_EXPECTED_BRANCH_ID", "S2A_EXPECTED_DEVICE_ID"):
        if not os.environ.get(field):
            parser.error("Missing required synthetic fixture environment: " + field)
    token = login()
    context = request("/rest/v1/rpc/get_receiving_context_v1", {}, token)
    check(context.get("kind") == "kiosk", "Synthetic kiosk context missing")
    for key in ("org_id", "branch_id", "device_id"):
        check(context.get(key) == os.environ["S2A_EXPECTED_" + key.upper()], "Synthetic fixture scope mismatch")
    pin = os.environ["S2A_VALID_SYNTHETIC_PIN"]
    initial = request("/rest/v1/rpc/begin_staff_session_v1", {"p_pin": pin}, token)
    check(initial.get("ok") is True, "Fresh synthetic fixture is not ready")
    request("/rest/v1/rpc/end_staff_session_v1", {
        "p_session_id": initial["session"]["id"], "p_session_secret": initial["session"]["secret"]
    }, token)
    initial.clear()
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        results = list(executor.map(lambda _: request("/rest/v1/rpc/begin_staff_session_v1", {"p_pin": "malformed"}, token), range(5)))
    check(all(row.get("ok") is False for row in results), "Invalid attempts unexpectedly succeeded")
    check(sum(row.get("error", {}).get("code") == "cooldown" for row in results) == 1, "Five serialized failures did not produce exactly one initial cooldown")
    denied = request("/rest/v1/rpc/begin_staff_session_v1", {"p_pin": pin}, token)
    check(denied.get("error", {}).get("code") == "cooldown", "Valid PIN bypassed cooldown")
    token = login()  # New client Auth token must not reset the permanent device row.
    repeated = request("/rest/v1/rpc/begin_staff_session_v1", {"p_pin": pin}, token)
    check(repeated.get("error", {}).get("code") == "cooldown", "Reauthentication reset cooldown")
    check(repeated["error"]["retry_after_seconds"] <= denied["error"]["retry_after_seconds"], "Cooldown was extended")
    expiry_checked = False
    if args.wait_for_expiry:
        time.sleep(repeated["error"]["retry_after_seconds"] + 1)
        renewed = request("/rest/v1/rpc/begin_staff_session_v1", {"p_pin": pin}, token)
        check(renewed.get("ok") is True, "Cooldown expiry did not allow valid verification")
        request("/rest/v1/rpc/end_staff_session_v1", {"p_session_id": renewed["session"]["id"], "p_session_secret": renewed["session"]["secret"]}, token)
        renewed.clear()
        expiry_checked = True
    print(json.dumps({"concurrent_invalid_attempts": 5, "durable_cooldown": "passed", "expiry_checked": expiry_checked,
                      "limits": "Does not certify all ACL/replay/audit/API races or baseline restoration."}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        raise SystemExit("Synthetic receiving API checks failed; no credential or response details logged.") from None
