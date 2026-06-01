import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Reads the `gh` CLI token on demand.
// Call request(); emits gotToken(token) or failed(message).
Item {
    id: deviceToken

    signal gotToken(string token)
    signal failed(string message)

    readonly property string cmd: "gh auth token"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            exec.disconnectSource(sourceName);
            var code = data["exit code"];
            var out = (data["stdout"] || "").trim();
            var err = (data["stderr"] || "").trim();
            if (code === 0 && out.length > 0) {
                deviceToken.gotToken(out);
            } else {
                deviceToken.failed(err.length > 0
                    ? err
                    : "Could not read gh token. Run `gh auth login`.");
            }
        }
    }

    function request() {
        exec.connectSource(deviceToken.cmd);
    }
}
