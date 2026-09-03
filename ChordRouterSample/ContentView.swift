import SwiftUI
import ChordRouter

struct ContentView: View {
	@State private var router: ChordRouter? = nil
	@State private var status = "Ready — try Cmd+K then Cmd+S"

	var body: some View {
		Text(status)
			.font(.system(size: 15, weight: .medium))
			.frame(width: 420, height: 160)
			.background(routerView)
			.onAppear(perform: setup)
	}

	@ViewBuilder
	private var routerView: some View {
		if let router {
			ChordCapturingViewRepresentable(router: router)
		}
	}

	private func setup() {
		guard router == nil else { return }

		let commands: [String: () -> Void] = [
			"app.saveAll":     { print("💾 saveAll() fired") },
			"app.commentLine": { print("💬 commentLine() fired") },
			"app.toggleZen":   { print("🧘 toggleZen() fired") }
		]

		do {
			let bindings = try ChordConfig.load(resource: "keybindings")
			let r = ChordRouter(keybindings: bindings, commands: commands)

			if !r.unboundCommands.isEmpty {
				print("⚠️ unbound commands:", r.unboundCommands)
			}

			r.onStateChange = { state in
				switch state {
				case .waiting(let key):           status = "⌛ \(key) … waiting"
				case .matched(let seq, let cmd):  status = "✅ \(seq) → \(cmd)"
				case .noMatch(let seq):           status = "❌ \(seq) — no match"
				case .unboundCommand(_, let cmd): status = "⚠️ no closure: \(cmd)"
				case .timedOut:                   status = "⏱ timed out"
				case .cancelled:                  status = "Ready"
				case .idle:                       break
				}
			}
			router = r
		} catch {
			status = "⚠️ \(error.localizedDescription)"
		}
	}
}
