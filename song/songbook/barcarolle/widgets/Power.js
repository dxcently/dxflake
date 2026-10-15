.pragma library

// The power actions, for every surface that offers them (the Shut Down dialog, the Start menu's power plate).
// An action: { name, action (the bridge's power verb), hint }.

var actions = [
    { name: "Log off", action: "logout",
      hint: "Closes your programs and ends your session so that someone else can log in." },
    { name: "Lock", action: "lock",
      hint: "Locks the screen. Your programs keep running and your password brings them back." },
    { name: "Restart", action: "reboot",
      hint: "Closes all programs, shuts down, and then starts the computer again." },
    { name: "Sleep", action: "suspend",
      hint: "Keeps your session in memory and puts the computer in a low-power state so that you can resume quickly." },
    { name: "Hibernate", action: "hibernate",
      hint: "Saves your session to disk and turns the computer off. It comes back where you left it." },
    { name: "Shut down", action: "shutdown",
      hint: "Closes all programs and turns the computer off so that you can safely cut the power." }
]

function find(action) {
    for (var i = 0; i < actions.length; i++) if (actions[i].action === action) return actions[i]
    return null
}
