/**
 * WeFix – Warranty Email Notification Cloud Functions
 *
 * Uses firebase functions.config() for credentials (works on Spark plan).
 * Deploy config first:
 *   firebase functions:config:set email.user="..." email.password="..."
 *
 * Functions:
 *  1. onWarrantyCreated   – Firestore trigger: confirmation email on save
 *  2. checkWarrantyExpiry – Scheduled daily: reminders at 30/15/3/1 days before expiry
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const moment = require("moment");

admin.initializeApp();
const db = admin.firestore();

// Days before expiry to send reminder emails
const REMINDER_DAYS = [30, 15, 3, 1];

// ── Helpers ───────────────────────────────────────────────────────────────────

function buildTransporter() {
    const cfg = functions.config().email;
    return nodemailer.createTransport({
        service: "gmail",
        auth: { user: cfg.user, pass: cfg.password },
    });
}

function getSenderAddress() {
    return `"WeFix" <${functions.config().email.user}>`;
}

/** Parse "1 Year", "3 Months", etc. → number of months  */
function parseValidityMonths(validity) {
    const map = {
        "1 Month": 1,
        "3 Months": 3,
        "6 Months": 6,
        "1 Year": 12,
        "2 Years": 24,
        "3 Years": 36,
        "5 Years": 60,
        Lifetime: 9999,
    };
    return map[validity] ?? 12;
}

/** Confirmation email sent right after warranty is saved */
function buildConfirmationEmail(data) {
    const purchaseDate = data.purchaseDate?.toDate
        ? moment(data.purchaseDate.toDate()).format("MMMM D, YYYY")
        : "N/A";
    const months = parseValidityMonths(data.warrantyValidity);
    const expiresOn =
        months === 9999
            ? "Never (Lifetime)"
            : data.purchaseDate?.toDate
                ? moment(data.purchaseDate.toDate())
                    .add(months, "months")
                    .format("MMMM D, YYYY")
                : "N/A";

    return {
        subject: `✅ Warranty Registered – ${data.modelName}`,
        html: `
<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:10px;">
  <h2 style="color:#1a56db;text-align:center;margin-bottom:4px;">WeFix</h2>
  <h3 style="text-align:center;margin-top:0;color:#374151;">Warranty Registered Successfully 🎉</h3>

  <p style="color:#374151;">Hi there,</p>
  <p style="color:#374151;">Your warranty has been securely recorded. Here are the details:</p>

  <div style="background:#f9fafb;border-radius:8px;padding:16px;margin:20px 0;">
    <p style="margin:6px 0;"><strong>Product:</strong> ${data.modelName}</p>
    <p style="margin:6px 0;"><strong>Model Number:</strong> ${data.modelNumber || "—"}</p>
    <p style="margin:6px 0;"><strong>Company:</strong> ${data.company || "—"}</p>
    <p style="margin:6px 0;"><strong>Purchase Date:</strong> ${purchaseDate}</p>
    <p style="margin:6px 0;"><strong>Warranty Period:</strong> ${data.warrantyValidity || "1 Year"}</p>
    <p style="margin:6px 0;"><strong>Warranty Expires On:</strong>
      <span style="color:#dc2626;font-weight:bold;">${expiresOn}</span>
    </p>
  </div>

  <p style="color:#374151;">We'll send you reminder emails <strong>30 days, 15 days, 3 days, and 1 day</strong>
  before your warranty expires so you never miss a claim window.</p>

  <p style="margin-top:28px;font-size:12px;color:#9ca3af;text-align:center;">
    This is an automated message from WeFix. Please do not reply to this email.
  </p>
</div>`,
    };
}

/** Reminder email sent X days before expiry */
function buildReminderEmail(data, daysRemaining, expiresOnFormatted) {
    const timeLabel =
        { 30: "30 days", 15: "15 days", 3: "3 days", 1: "1 day" }[
        daysRemaining
        ] ?? `${daysRemaining} days`;
    const urgencyColor = daysRemaining <= 3 ? "#dc2626" : "#d97706";
    const purchaseDate = data.purchaseDate?.toDate
        ? moment(data.purchaseDate.toDate()).format("MMMM D, YYYY")
        : "N/A";

    return {
        subject: `⚠️ Warranty Expiring in ${timeLabel} – ${data.modelName}`,
        html: `
<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:10px;">
  <h2 style="color:#1a56db;text-align:center;margin-bottom:4px;">WeFix</h2>
  <h3 style="text-align:center;margin-top:0;color:#374151;">Warranty Expiration Notice</h3>

  <p style="color:#374151;">Dear WeFix User,</p>
  <p style="color:#374151;">This is a friendly reminder that your warranty is expiring soon:</p>

  <div style="background:#fff7ed;border-left:4px solid ${urgencyColor};border-radius:6px;padding:16px;margin:20px 0;">
    <p style="margin:0;font-size:16px;font-weight:bold;color:${urgencyColor};">
      ⏰ Expires in <span style="font-size:20px;">${timeLabel}</span> — ${expiresOnFormatted}
    </p>
  </div>

  <div style="background:#f9fafb;border-radius:8px;padding:16px;margin:20px 0;">
    <p style="margin:6px 0;"><strong>Product:</strong> ${data.modelName}</p>
    <p style="margin:6px 0;"><strong>Model Number:</strong> ${data.modelNumber || "—"}</p>
    <p style="margin:6px 0;"><strong>Company:</strong> ${data.company || "—"}</p>
    <p style="margin:6px 0;"><strong>Purchase Date:</strong> ${purchaseDate}</p>
    <p style="margin:6px 0;"><strong>Warranty Validity:</strong> ${data.warrantyValidity || "1 Year"}</p>
  </div>

  <p style="color:#374151;">If you need to extend your warranty or arrange for service,
  please contact <strong>${data.company || "the manufacturer"}</strong> before your warranty expires.</p>

  <p style="margin-top:28px;font-size:12px;color:#9ca3af;text-align:center;">
    This is an automated message from WeFix. Please do not reply to this email.
  </p>
</div>`,
    };
}

// ── 1. Firestore Trigger: new warranty → confirmation email ───────────────────
exports.onWarrantyCreated = functions.firestore
    .document("users/{userId}/warranties/{warrantyId}")
    .onCreate(async (snap) => {
        const data = snap.data();
        const email = data?.email;

        if (!email) {
            functions.logger.log("No email on warranty – skipping confirmation.");
            return;
        }

        const transporter = buildTransporter();
        const { subject, html } = buildConfirmationEmail(data);

        try {
            await transporter.sendMail({
                from: getSenderAddress(),
                to: email,
                subject,
                html,
            });
            functions.logger.log(`Confirmation email sent to ${email}`);
        } catch (err) {
            functions.logger.error("Failed to send confirmation email:", err);
        }
    });

// ── 2. Scheduled: daily expiry check → reminder emails ───────────────────────
exports.checkWarrantyExpiry = functions.pubsub
    .schedule("every day 09:00")
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
        functions.logger.log("Starting daily warranty expiry check...");

        const transporter = buildTransporter();
        const today = moment().startOf("day");

        const usersSnap = await db.collection("users").get();
        functions.logger.log(`Checking ${usersSnap.size} users`);

        for (const userDoc of usersSnap.docs) {
            const warrantiesSnap = await db
                .collection("users")
                .doc(userDoc.id)
                .collection("warranties")
                .get();

            for (const wDoc of warrantiesSnap.docs) {
                const data = wDoc.data();
                const email = data.email;

                if (!email || !data.purchaseDate) continue;

                const months = parseValidityMonths(data.warrantyValidity);
                if (months === 9999) continue; // Lifetime — skip

                const purchaseDate = moment(data.purchaseDate.toDate());
                const expiryDate = purchaseDate.clone().add(months, "months");
                const daysUntilExpiry = expiryDate.diff(today, "days");

                if (!REMINDER_DAYS.includes(daysUntilExpiry)) continue;

                // Dedup — don't resend if already sent for this interval
                const sentIntervals = data.notificationsSent ?? [];
                if (sentIntervals.includes(daysUntilExpiry)) {
                    functions.logger.log(
                        `Already sent ${daysUntilExpiry}d reminder for ${wDoc.id}`
                    );
                    continue;
                }

                const expiresOnFormatted = expiryDate.format("MMMM D, YYYY");
                const { subject, html } = buildReminderEmail(
                    data,
                    daysUntilExpiry,
                    expiresOnFormatted
                );

                try {
                    await transporter.sendMail({
                        from: getSenderAddress(),
                        to: email,
                        subject,
                        html,
                    });
                    functions.logger.log(
                        `Reminder (${daysUntilExpiry}d) sent to ${email} for ${wDoc.id}`
                    );

                    // Mark interval as sent so we don't re-email
                    await wDoc.ref.update({
                        notificationsSent: admin.firestore.FieldValue.arrayUnion(
                            daysUntilExpiry
                        ),
                    });
                } catch (err) {
                    functions.logger.error(
                        `Reminder email failed for ${wDoc.id} / ${email}:`,
                        err
                    );
                }
            }
        }

        functions.logger.log("Daily warranty expiry check complete.");
        return null;
    });
