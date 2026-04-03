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
    const emailConfig = functions.config().email;
    if (!emailConfig || !emailConfig.user || !emailConfig.password) {
        throw new Error(
            "Missing 'email.user' or 'email.password' in functions.config(). Please run `firebase functions:config:set email.user=... email.password=...` and redeploy.",
        );
    }
    return nodemailer.createTransport({
        service: "gmail",
        auth: { user: emailConfig.user, pass: emailConfig.password },
    });
}

function getSenderAddress() {
    const emailConfig = functions.config().email;
    if (!emailConfig || !emailConfig.user) {
        return `"WeFix" <noreply@wefix.com>`;
    }
    return `"WeFix" <${emailConfig.user}>`;
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
        ? moment.utc(data.purchaseDate.toDate()).format("MMMM D, YYYY")
        : "N/A";
    const months = parseValidityMonths(data.warrantyValidity);
    const expiresOn =
        months === 9999
            ? "Never (Lifetime)"
            : data.purchaseDate?.toDate
                ? moment
                    .utc(data.purchaseDate.toDate())
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
        { 30: "30 days", 15: "15 days", 3: "3 days", 1: "1 day" }[daysRemaining] ??
        `${daysRemaining} days`;
    const urgencyColor = daysRemaining <= 3 ? "#dc2626" : "#d97706";
    const purchaseDate = data.purchaseDate?.toDate
        ? moment.utc(data.purchaseDate.toDate()).format("MMMM D, YYYY")
        : "N/A";

    return {
        subject: `⚠️ Warranty Expiring in ${timeLabel} – ${data.modelName}`,
        html: `
<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;border:1px solid #e5e7eb;border-radius:10px;">
  <h2 style="color:#1a56db;text-align:center;margin-bottom:4px;">WeFix</h2>
  <h3 style="text-align:center;margin-top:0;color:#374151;">Warranty Expiration Alert ⚠️</h3>

  <p style="color:#374151;">Hi there,</p>
  <p style="color:#374151;">This is a friendly reminder that your warranty will expire in <strong>${timeLabel}</strong>. Here are the details:</p>

  <div style="background:#fff7ed;border-left:4px solid ${urgencyColor};border-radius:6px;padding:16px;margin:20px 0;">
    <p style="margin:0;font-size:16px;font-weight:bold;color:${urgencyColor};">
      ⏰ Expires on — ${expiresOnFormatted}
    </p>
  </div>

  <div style="background:#f9fafb;border-radius:8px;padding:16px;margin:20px 0;">
    <p style="margin:6px 0;"><strong>Product:</strong> ${data.modelName}</p>
    <p style="margin:6px 0;"><strong>Model Number:</strong> ${data.modelNumber || "—"}</p>
    <p style="margin:6px 0;"><strong>Company:</strong> ${data.company || "—"}</p>
    <p style="margin:6px 0;"><strong>Purchase Date:</strong> ${purchaseDate}</p>
    <p style="margin:6px 0;"><strong>Warranty Period:</strong> ${data.warrantyValidity || "1 Year"}</p>
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

        try {
            functions.logger.log(`Building transporter for email...`);
            const transporter = buildTransporter();
            const { subject, html } = buildConfirmationEmail(data);

            functions.logger.log(`Attempting to send confirmation email to ${email}`);
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
                        `Already sent ${daysUntilExpiry}d reminder for ${wDoc.id}`,
                    );
                    continue;
                }

                const expiresOnFormatted = expiryDate.format("MMMM D, YYYY");
                const { subject, html } = buildReminderEmail(
                    data,
                    daysUntilExpiry,
                    expiresOnFormatted,
                );

                try {
                    await transporter.sendMail({
                        from: getSenderAddress(),
                        to: email,
                        subject,
                        html,
                    });
                    functions.logger.log(
                        `Reminder (${daysUntilExpiry}d) sent to ${email} for ${wDoc.id}`,
                    );

                    // Mark interval as sent so we don't re-email
                    await wDoc.ref.update({
                        notificationsSent:
                            admin.firestore.FieldValue.arrayUnion(daysUntilExpiry),
                    });
                } catch (err) {
                    functions.logger.error(
                        `Reminder email failed for ${wDoc.id} / ${email}:`,
                        err,
                    );
                }
            }
        }

        functions.logger.log("Daily warranty expiry check complete.");
        return null;
    });

// ── 3. Firestore Trigger: Service Request Status Updates → Push Notifications ──
exports.onRequestStatusChanged = functions.firestore
    .document("shop_users/{shopId}/requests/{requestId}")
    .onWrite(async (change, context) => {
        const { shopId, requestId } = context.params;

        // Document deleted
        if (!change.after.exists) return null;

        const dataBefore = change.before.data() || {};
        const dataAfter = change.after.data();

        const statusBefore = dataBefore.status;
        const statusAfter = dataAfter.status;
        const revBefore = dataBefore.reverseDropScheduled;
        const revAfter = dataAfter.reverseDropScheduled;
        const userId = dataAfter.userId;

        // We care if the status changed OR if a reverse drop was just scheduled
        const statusChanged = statusBefore !== statusAfter;
        const reverseScheduled = !revBefore && revAfter;

        if (!statusChanged && !reverseScheduled) return null;
        if (!userId) {
            functions.logger.warn(`No userId found for request ${requestId}`);
            return null;
        }

        // Fetch User's FCM Token
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
        if (!userDoc.exists) return null;

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            functions.logger.log(`User ${userId} has no fcmToken registered.`);
            return null;
        }

        // Fetch Shop details for shop name
        const shopDoc = await admin
            .firestore()
            .collection("shop_users")
            .doc(shopId)
            .get();
        const shopName = shopDoc.exists
            ? (shopDoc.data().companyLegalName ||
               shopDoc.data().companyLegalname ||
               shopDoc.data().companylegalName ||
               "the shop")
            : "the shop";

        // Map status to Title and Body
        let title = "WeFix Update";
        let body = "";

        if (reverseScheduled) {
            title = "Courier Scheduled 🚚";
            body = `Your device is on its way back! A courier has been scheduled by ${shopName} to return your item.`;
        } else {
            switch (statusAfter) {
            case "pending":
            case "Pending":
                title = "Request Sent";
                body = `Your request has been sent to ${shopName}.`;
                break;
            case "waiting_for_confirmation":
                title = "Estimate Received";
                if (dataAfter.isHeavyAppliance) {
                    body = `${shopName} has estimated a visit charge of ₹${dataAfter.amount || "0"}. Please accept and schedule your visit time.`;
                } else {
                    body = `The ${shopName} has estimated a budget of ₹${dataAfter.amount || "0"} for your service. Please accept or decline to move further.`;
                }
                break;
            case "in_progress":
                title = dataAfter.isHeavyAppliance ? "Home Visit Scheduled" : "Request Accepted";
                if (dataAfter.isHeavyAppliance) {
                    const scheduledDate = dataAfter.visitScheduledAt 
                        ? (dataAfter.visitScheduledAt.toDate ? dataAfter.visitScheduledAt.toDate().toLocaleString() : dataAfter.visitScheduledAt)
                        : "the chosen time";
                    body = `Your home-visit is set! A technician from ${shopName} will arrive at your location at ${scheduledDate}.`;
                } else {
                    body = `Your request was accepted by ${shopName}. Please drop off or courier the product to the shop location.`;
                }
                break;
            case "in_service":
                title = "Product Received";
                body = `Your product was received by the shop keeper.`;
                break;
            case "payment_required":
                title = "Payment Required";
                body = `Your service is completed! Please make the payment of ₹${dataAfter.amount || ""} to get your device back.`;
                break;
            case "completed":
                title = "Service Completed";
                body = `Payment done! Your service is completely finished. Please rate the service in the app.`;
                break;
            case "declined":
                title = "Request Declined";
                body = `Unfortunately, the shop declined your service request.`;
                break;
                // No notification for other generic statuses
                return null;
            }
        }

        // Send Push Notification
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: { sound: "default" },
                },
            },
            data: {
                requestId: requestId,
                shopId: shopId,
            },
        };

        try {
            // Send FCM
            const response = await admin.messaging().send(message);
            functions.logger.log(
                `Push sent successfully for ${requestId} (${statusAfter}):`,
                response,
            );

            // Save to User's Notifications Subcollection
            let type = "info";
            if (reverseScheduled) {
                type = "success";
            } else {
                if (statusAfter === "payment_required" || statusAfter === "waiting_for_confirmation") type = "warning";
                if (statusAfter === "payment_done" || statusAfter === "completed") type = "success";
                if (statusAfter === "declined") type = "error";
            }

            await admin.firestore()
                .collection("users")
                .doc(userId)
                .collection("notifications")
                .add({
                    title: title,
                    body: body,
                    type: type,
                    requestId: requestId,
                    shopId: shopId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false,
                });

        } catch (error) {
            functions.logger.error(`Error sending push/saving notification for ${requestId}:`, error);
        }

        return null;
    });

// ── 4. Borzo Business API Integration ─────────────────────────────────────────

const BORZO_API_URL = "https://robotapitest-in.borzodelivery.com/api/business/1.6";

function getBorzoToken() {
    const borzoConfig = { auth_token: process.env.BORZO_AUTH_TOKEN };
    if (!borzoConfig || !borzoConfig.auth_token) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Missing 'borzo.auth_token' in functions.config()."
        );
    }
    return borzoConfig.auth_token;
}

exports.calculateBorzoOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
    }

    const { points, matter, total_weight_kg, type } = data;
    if (!points || points.length < 2) {
        throw new functions.https.HttpsError("invalid-argument", "At least 2 points are required for calculation.");
    }

    const token = getBorzoToken();

    try {
        const response = await fetch(`${BORZO_API_URL}/calculate-order`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-DV-Auth-Token": token,
            },
            body: JSON.stringify({
                type: type || "standard",
                matter: matter || "Electronics / Repair Item",
                total_weight_kg: total_weight_kg || 1,
                points: points,
            }),
        });

        const result = await response.json();
        if (!response.ok || !result.is_successful) {
            functions.logger.error("Borzo Calc Error:", result);
            throw new functions.https.HttpsError("internal", "Borzo API calculation failed.");
        }

        return result.order;
    } catch (error) {
        functions.logger.error("Error calling Borzo calculate-order:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

exports.createBorzoOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
    }

    const { points, matter, total_weight_kg, vehicle_type_id, type, requestId, shopId, isReverseDrop } = data;
    if (!points || points.length < 2) {
        throw new functions.https.HttpsError("invalid-argument", "At least 2 points are required.");
    }

    const token = getBorzoToken();

    try {
        const response = await fetch(`${BORZO_API_URL}/create-order`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-DV-Auth-Token": token,
            },
            body: JSON.stringify({
                type: type || "standard",
                matter: matter || "Electronics / Repair Item",
                total_weight_kg: total_weight_kg || 1,
                vehicle_type_id: vehicle_type_id || 8, // 8 = motorbike
                is_client_notification_enabled: true,
                is_contact_person_notification_enabled: true,
                points: points,
            }),
        });

        const result = await response.json();
        if (!response.ok || !result.is_successful) {
            functions.logger.error("Borzo Create Error:", result);
            throw new functions.https.HttpsError("internal", "Borzo API create-order failed: " + JSON.stringify(result));
        }

        const order = result.order;

        // Route fields dynamically: Reverse Drop vs. Forward Drop
        if (requestId && shopId) {
            const updatePayload = {};
            if (isReverseDrop) {
                updatePayload.reverseDropScheduled = true;
                updatePayload.reverseBorzoOrderId = order.order_id;
                updatePayload.reverseBorzoTrackingUrl = order.points[0]?.tracking_url || null;
                updatePayload.reverseBorzoStatus = order.status;
            } else {
                updatePayload.borzoOrderId = order.order_id;
                updatePayload.borzoTrackingUrl = order.points[0]?.tracking_url || null;
                updatePayload.borzoStatus = order.status;
                updatePayload.borzoDeliveryCost = order.payment_amount ? order.payment_amount.toString() : null;
            }
            await db.collection("shop_users").doc(shopId).collection("requests").doc(requestId).update(updatePayload);

            // Create a lookup entry for rapid, index-free webhook status updates
            await db.collection("borzo_order_lookups").doc(order.order_id.toString()).set({
                shopId: shopId,
                requestId: requestId,
                isReverse: isReverseDrop || false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        return order;
    } catch (error) {
        functions.logger.error("Error calling Borzo create-order:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

exports.borzoWebhook = functions.https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
    }

    const data = req.body;
    functions.logger.log("Incoming Borzo Webhook Payload:", JSON.stringify(data));

    if (!data) return res.status(400).send("Empty Payload");

    // Borzo has two formats: Order Callback (data.order) and Delivery Callback (data.delivery)
    const order = data.order || data.delivery;
    if (!order || !order.order_id) {
        functions.logger.warn("Borzo Webhook: Missing order_id in payload.");
        return res.status(200).send("OK - No action taken (Missing order_id)");
    }

    const orderId = order.order_id;
    const newStatus = order.status;

    try {
        const orderIdStr = orderId.toString();

        // Use a direct lookup instead of a collectionGroup query (No index needed!)
        const lookupSnap = await db.collection("borzo_order_lookups").doc(orderIdStr).get();

        if (!lookupSnap.exists) {
            functions.logger.warn(`Borzo Webhook: No mapping found for Order ID ${orderIdStr}`);
            return res.status(200).send("OK - No mapping found");
        }

        const { shopId, requestId, isReverse } = lookupSnap.data();
        const requestRef = db.collection("shop_users").doc(shopId).collection("requests").doc(requestId);

        if (isReverse) {
            await requestRef.update({
                reverseBorzoStatus: newStatus,
                reverseBorzoStatusDescription: order.status_description || "Updated via Webhook"
            });
            functions.logger.log(`Updated REVERSE status for Request ${requestId} to ${newStatus}`);
        } else {
            await requestRef.update({
                borzoStatus: newStatus,
                borzoStatusDescription: order.status_description || "Updated via Webhook"
            });
            functions.logger.log(`Updated FORWARD status for Request ${requestId} to ${newStatus}`);
        }

        return res.status(200).send("OK");
    } catch (error) {
        functions.logger.error("Webhook processing error:", error);
        return res.status(500).send("Internal Server Error");
    }
});