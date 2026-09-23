# Al Safa Market OS

Al Safa Market OS is a mobile-friendly grocery inventory and expiration management application. It currently runs as a browser-based Progressive Web App and stores its data locally, allowing the full interface to be tested without a database.

## Test the Application

The current local preview is available at:

```text
http://localhost:8010/
```

Demo logins:

| Role | PIN | Access |
| --- | --- | --- |
| Owner | `1111` | Full access |
| Manager | `2222` | Inventory, reports, purchase orders, and activity logs |
| Employee | `3333` | Add and update inventory; no financial data |

## Core Inventory Features

- Add, edit, search, filter, and delete products
- Product name used as the primary inventory identifier
- Optional barcode
- Category, supplier, quantity, cost, retail price, expiration date, shelf location, and notes
- Automatic days-until-expiration calculation
- CSV export
- Browser local-storage persistence
- Mobile-friendly product intake and receiving forms

Expiration status colors:

- Red: expired or expiring in 0-7 days
- Yellow: expiring in 8-30 days
- Green: 31 or more days remaining

## Scan Product by Photo

The Add/Edit Product form includes **Scan Product by Photo**.

The employee can take a photo with a mobile camera or upload an existing product image. The scan review form supports:

- Product name
- Brand
- Expiration date
- Size or weight
- Category

The employee must review and apply the extracted fields before saving. The application never automatically saves scan results. Fields below the confidence threshold are left blank for manual entry.

The product record retains:

- The reviewed product information
- Brand and size/weight metadata
- The saved product photo
- The date the photo scan was reviewed

Product name remains the primary identifier.

The local browser version provides the complete capture, review, confidence, and storage workflow. Production OCR or AI vision requires a secure backend endpoint configured through `VISION_ENDPOINT` in `app.js`. API credentials must not be placed in browser code.

## Dashboards and Reports

### Daily Expiration Dashboard

- Expired today
- Expires within 7 days
- Expires within 30 days
- Mark Down Product action
- Discount percentage, quantity sold, and waste avoided tracking

### Owner Dashboard

- Total inventory value at cost
- Total inventory value at retail
- Potential gross profit
- Inventory units
- Top 20 highest-value products
- Inventory by category

### Executive Dashboard

- Inventory value
- Products expiring within 7 days
- Products expiring within 30 days
- Low-stock products
- Highest-value inventory
- Weekly waste estimate
- Monthly inventory summary

### Supplier Dashboard

- Number of deliveries
- Average shelf life received
- Products received expired or near expiration
- Inventory losses by supplier

### AI Insights

The local rules-based insights page analyzes:

- Expiration patterns
- Waste and markdown trends
- Slow-moving products
- Supplier risk
- Low-stock exposure
- Recommended actions

No external AI service is required for the current local insights.

## Receiving and Purchasing

### Inventory Intake

The intake form supports product name, category, quantity, expiration date, supplier, cost, retail price, shelf location, and optional barcode. A matching product name adds quantity to the existing product.

### Receiving Log

Each receiving entry records:

- Product name
- Supplier
- Arrival date
- Expiration date
- Quantity
- Automatically calculated shelf life

### Purchase Orders

Users with permission can select a supplier, choose products, enter quantities, generate a purchase order, and use the browser print dialog to save it as a PDF.

## Reminders

The default reminder address is:

```text
sales@alsafamarket.com
```

The Settings page includes configurable expiration thresholds and previews for:

- Daily expiration reminders
- Products expiring this week
- Products expiring this month
- Low-stock products
- Products not updated in 30 days
- Weekly Monday 8:00 AM inventory report

The local app can prepare email drafts. Fully automatic email delivery requires a backend scheduler, shared data storage, and an email provider such as Resend, SendGrid, Postmark, Mailgun, Amazon SES, or SMTP.

## Progressive Web App

The application includes:

- Web app manifest
- Service worker and offline cache
- Offline fallback page
- Android and iPhone home-screen icons
- Standalone installed-app display
- Browser notification permission flow
- Push-event handling in the service worker

Installation:

- iPhone or iPad: open in Safari, tap **Share**, then **Add to Home Screen**
- Android: open in Chrome and choose **Install app** or **Add to Home screen**

Remote push delivery requires HTTPS, VAPID keys, a backend subscription endpoint, and a scheduled push sender.

## Activity Logs

The application records:

- Logins and logouts
- Product additions, edits, and deletions
- Inventory intake
- Receiving activity
- Markdown activity
- Purchase orders
- Settings changes
- CSV exports
- Photo-scan review activity
- PWA alert and installation activity

Only the Owner can clear activity logs.

## Local Setup

No package installation or database is required.

From the project folder, run:

```bash
python3 -m http.server 8010
```

Then open:

```text
http://localhost:8010/
```

A local server or HTTPS is required for PWA installation, service workers, offline caching, and browser notifications. Opening `index.html` directly is suitable only for basic interface testing.

## Local Data Keys

The app stores data under these browser local-storage keys:

```text
alsafa-market-inventory
alsafa-market-settings
alsafa-market-markdowns
alsafa-market-receiving-log
alsafa-market-purchase-orders
alsafa-market-activity-log
alsafa-market-current-user
alsafa-market-pwa-alerts
alsafa-market-push-subscription
```

Clearing site data removes locally stored inventory and settings.

## Production Requirements

Before production use, add:

1. Secure server-side authentication and password storage.
2. A shared database so multiple devices see the same inventory.
3. Server-side role and permission enforcement.
4. Secure object storage for product photos.
5. A protected OCR or AI vision endpoint.
6. Scheduled email and Web Push workers.
7. HTTPS hosting, backups, audit retention, and data recovery.

The current version is designed for local testing and workflow validation. Browser-only login rules and local storage are not substitutes for production security or shared business data.
