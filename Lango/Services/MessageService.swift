import Foundation

enum LangoError: Error, CustomStringConvertible {
    case notConfigured
    case missingSlotData
    case invalidURL(String)
    case sendFailed(status: Int, body: String)
    case templateNotFound(String)

    var description: String {
        switch self {
        case .notConfigured:
            return "Kapso API key or phone-number ID not set"
        case .missingSlotData:
            return "Slot missing template name or recipient phone"
        case .invalidURL(let s):
            return "Invalid Kapso URL: \(s)"
        case .sendFailed(let status, let body):
            return "Send failed (\(status)): \(body)"
        case .templateNotFound(let name):
            return "Kapso/Meta doesn't recognise template '\(name)'"
        }
    }
}

/// The phone's only outbound channel. Calls Kapso's Meta-proxy directly:
/// `POST https://api.kapso.ai/meta/whatsapp/v24.0/<phone_id>/messages`
/// with `X-API-Key: <KAPSO_API_KEY>` and a WhatsApp template body.
///
/// No proxy, no Worker, no Kapso function in between. Kapso is the entire
/// backend — they hold the WhatsApp Business Account, the phone number, and
/// the Meta token. The iPhone holds only the Kapso API key (in Keychain) and
/// per-slot routing (template name + recipient phone).
enum MessageService {
    static let kapsoBaseURL = "https://api.kapso.ai/meta/whatsapp/v24.0"

    /// Send a WhatsApp template message via Kapso.
    /// - Parameters:
    ///   - templateName: Meta template name (e.g. "gate_open"). Must be approved.
    ///   - recipientPhone: International format, digits only (e.g. "2547XXXXXXXX").
    static func send(templateName: String, recipientPhone: String) async throws {
        guard AppConfig.isConfigured else {
            throw LangoError.notConfigured
        }
        guard !templateName.isEmpty, !recipientPhone.isEmpty else {
            throw LangoError.missingSlotData
        }

        let urlString = "\(kapsoBaseURL)/\(AppConfig.kapsoPhoneNumberID)/messages"
        guard let url = URL(string: urlString) else {
            throw LangoError.invalidURL(urlString)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(AppConfig.kapsoAPIKey, forHTTPHeaderField: "X-API-Key")
        req.timeoutInterval = 15

        let body: [String: Any] = [
            "messaging_product": "whatsapp",
            "to": recipientPhone,
            "type": "template",
            "template": [
                "name": templateName,
                "language": ["code": "en"],
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw LangoError.sendFailed(status: -1, body: "no HTTP response")
        }

        // Meta returns 200 with a `messages[0].id` (wamid) on success.
        // Non-200 → surface the body for diagnosis. Template not found is a
        // common one worth recognising specifically.
        guard http.statusCode == 200 else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            // Meta returns code 132001 for "template not found / not approved".
            if bodyString.contains("132001") || bodyString.contains("template name does not exist") {
                throw LangoError.templateNotFound(templateName)
            }
            throw LangoError.sendFailed(status: http.statusCode, body: bodyString)
        }
    }
}
