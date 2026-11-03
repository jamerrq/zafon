function deviceLabel(device) {
  if (!device) return ""
  return String(device.deviceName || device.name || "").trim()
}

// Nerd Font glyphs (Material Design Icons) for the device classes BlueZ
// reports through its freedesktop `Icon` property.
var GLYPHS = {
  headphones: "\u{F02CB}",
  headset: "\u{F02CE}",
  gamepad: "\u{F0297}",
  keyboard: "\u{F030C}",
  mouse: "\u{F037D}",
  speaker: "\u{F04C3}",
  phone: "\u{F011C}",
  laptop: "\u{F0322}",
  audio: "\u{F00B0}",
  bluetooth: "\u{F00AF}"
}

function iconForText(value) {
  var text = String(value || "").toLowerCase()
  if (text === "") return ""
  if (text.indexOf("headset") !== -1) return GLYPHS.headset
  if (text.indexOf("headphone") !== -1 || text.indexOf("earbud") !== -1) return GLYPHS.headphones
  if (text.indexOf("gaming") !== -1 || text.indexOf("joystick") !== -1
      || text.indexOf("gamepad") !== -1 || text.indexOf("controller") !== -1) return GLYPHS.gamepad
  if (text.indexOf("keyboard") !== -1) return GLYPHS.keyboard
  if (text.indexOf("mouse") !== -1) return GLYPHS.mouse
  if (text.indexOf("speaker") !== -1) return GLYPHS.speaker
  if (text.indexOf("phone") !== -1) return GLYPHS.phone
  if (text.indexOf("computer") !== -1 || text.indexOf("laptop") !== -1) return GLYPHS.laptop
  if (text.indexOf("audio") !== -1) return GLYPHS.audio
  return ""
}

// The BlueZ `Icon` name is authoritative; the display name covers devices
// that ship a generic icon (or none) but announce their class in the name.
function deviceIcon(device) {
  if (!device) return GLYPHS.bluetooth
  return iconForText(device.icon) || iconForText(deviceLabel(device)) || GLYPHS.bluetooth
}

function clampPercent(value) {
  var number = Number(value)
  if (!isFinite(number)) return 0
  number = Math.round(number)
  if (number < 0) return 0
  if (number > 100) return 100
  return number
}

// Pull a Bluetooth address out of arbitrary text (UPower native paths look
// like "ps-controller-battery-a4:53:85:0c:48:db", so normalizing the whole
// string would eat the hex-looking letters in the prefix).
function addressFromText(value) {
  var match = String(value || "").match(/([0-9a-f]{2}[:-]){5}[0-9a-f]{2}/i)
  return match ? normalizedAddress(match[0]) : ""
}

// BlueZ itself only reports battery for devices implementing Battery1, so
// peripherals such as controllers surface their charge through UPower
// (hid-playstation et al. register a power supply) instead.
function upowerPercent(device, upowerDevices) {
  var address = normalizedAddress(device && device.address)
  var label = deviceLabel(device).toLowerCase()
  var byModel = null
  var list = toArray(upowerDevices)

  for (var i = 0; i < list.length; i++) {
    var upower = list[i]
    if (!upower || upower.ready === false || upower.isPresent === false) continue
    if (typeof upower.percentage !== "number" || upower.percentage <= 0) continue

    var nativePath = String(upower.nativePath || "")
    if (address !== "" && addressFromText(nativePath) === address) return clampPercent(upower.percentage * 100)

    // Model names collide when two of the same device are paired, so only
    // use one when nothing matched by address.
    var model = String(upower.model || "").toLowerCase()
    if (byModel === null && label !== "" && model === label) byModel = upower
  }

  return byModel === null ? null : clampPercent(byModel.percentage * 100)
}

function deviceBattery(device, upowerDevices) {
  if (!device) return { available: false, percent: 0 }
  // BlueZ's own Battery1 property when the device implements it.
  if (device.batteryAvailable && typeof device.battery === "number")
    return { available: true, percent: clampPercent(device.battery * 100) }

  var percent = upowerPercent(device, upowerDevices)
  return percent === null ? { available: false, percent: 0 } : { available: true, percent: percent }
}

function toArray(values) {
  if (!values) return []
  if (Array.isArray(values)) return values.slice()

  var length = Number(values.length || 0)
  if (!isFinite(length) || length <= 0) return []

  var list = []
  for (var i = 0; i < length; i++) list.push(values[i])
  return list
}

function isUuidLike(value) {
  var text = String(value || "").trim()
  if (text === "") return false
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(text)
    || /^[0-9a-f]{32}$/i.test(text)
    || /^0x[0-9a-f]{4,32}$/i.test(text)
    || /^0000[0-9a-f]{4}-0000-1000-8000-00805f9b34fb$/i.test(text)
}

function isAddressLike(value) {
  var text = String(value || "").trim()
  return /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(text)
}

function normalizedAddress(value) {
  return String(value || "").trim().toLowerCase().replace(/[^0-9a-f]/g, "")
}

function hasHumanName(device) {
  var label = deviceLabel(device)
  return label !== "" && !isUuidLike(label) && !isAddressLike(label)
}

function nodeProps(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function nodeText(node) {
  var props = nodeProps(node)
  return [
    node ? node.name : "",
    node ? node.description : "",
    node ? node.nickname : "",
    node ? node.nick : "",
    props["node.name"],
    props["node.description"],
    props["node.nick"],
    props["device.name"],
    props["device.description"],
    props["device.product.name"],
    props["device.alias"],
    props["device.string"],
    props["api.bluez5.address"],
    props["bluez5.address"],
    props["media.name"]
  ].join(" ").toLowerCase()
}

function bluetoothSinkMatchesDevice(node, device) {
  if (!node || !node.isSink || node.isStream || !device) return false

  var address = normalizedAddress(device.address)
  var text = nodeText(node)
  if (address !== "" && normalizedAddress(text).indexOf(address) !== -1) return true

  var label = deviceLabel(device).toLowerCase()
  return label !== "" && text.indexOf(label) !== -1
}

function sortedByLabel(devices) {
  var list = toArray(devices)
  list.sort(function(a, b) { return deviceLabel(a).localeCompare(deviceLabel(b)) })
  return list
}

// Primitives-only projection of a BlueZ device for list-model rows. Holding
// the Device QObject in model data puts a live wrapper into every delegate's
// var property, and BlueZ churn (discovery timeouts, unpair) can destroy the
// object while a delegate is still incubating, which segfaults quickshell.
// Actions resolve the backend object via Panel.deviceFor().
function deviceRow(d, upowerDevices) {
  if (!d) return null
  var battery = deviceBattery(d, upowerDevices)
  return {
    address: d.address || "",
    name: d.name || "",
    deviceName: d.deviceName || "",
    connected: !!d.connected,
    state: d.state !== undefined ? d.state : -1,
    batteryAvailable: battery.available,
    batteryPercent: battery.percent,
    pairing: !!d.pairing,
    icon: deviceIcon(d)
  }
}

// One bar entry per connected device that reports a charge, so several
// peripherals can be watched side by side.
function batteryEntries(devices, upowerDevices) {
  var values = toArray(devices)
  var entries = []

  for (var i = 0; i < values.length; i++) {
    var d = values[i]
    if (!d || !d.connected) continue
    var battery = deviceBattery(d, upowerDevices)
    if (!battery.available) continue
    entries.push({
      address: d.address || "",
      label: deviceLabel(d),
      icon: deviceIcon(d),
      percent: battery.percent
    })
  }

  return entries
}

function deviceLists(devices) {
  var values = toArray(devices)
  var connected = []
  var known = []
  var discovered = []

  for (var i = 0; i < values.length; i++) {
    var d = values[i]
    if (!d || !hasHumanName(d)) continue
    if (d.connected) connected.push(d)
    else if (d.paired || d.bonded || d.trusted) known.push(d)
    else discovered.push(d)
  }

  return {
    connected: sortedByLabel(connected),
    known: sortedByLabel(known),
    discovered: sortedByLabel(discovered)
  }
}

function cloneMap(map) {
  var next = ({})
  for (var key in map || {}) next[key] = map[key]
  return next
}

function pendingAction(actions, address) {
  return address && actions && actions[address] ? actions[address] : ""
}

function withPendingAction(actions, address, action) {
  var next = cloneMap(actions)
  if (!address) return next
  if (action) next[address] = action
  else delete next[address]
  return next
}

function visibleSections(lists, discovering) {
  var sections = []
  if (lists && lists.connected && lists.connected.length > 0) sections.push("connected")
  if (lists && lists.known && lists.known.length > 0) sections.push("known")
  if (discovering && lists && lists.discovered && lists.discovered.length > 0) sections.push("discovered")
  return sections
}

function sectionDevices(lists, section) {
  if (!lists) return []
  if (section === "connected") return lists.connected || []
  if (section === "known") return lists.known || []
  if (section === "discovered") return lists.discovered || []
  return []
}

if (typeof module !== "undefined") {
  module.exports = {
    deviceLabel: deviceLabel,
    toArray: toArray,
    isUuidLike: isUuidLike,
    isAddressLike: isAddressLike,
    normalizedAddress: normalizedAddress,
    hasHumanName: hasHumanName,
    nodeProps: nodeProps,
    nodeText: nodeText,
    bluetoothSinkMatchesDevice: bluetoothSinkMatchesDevice,
    sortedByLabel: sortedByLabel,
    deviceIcon: deviceIcon,
    deviceBattery: deviceBattery,
    deviceRow: deviceRow,
    batteryEntries: batteryEntries,
    deviceLists: deviceLists,
    cloneMap: cloneMap,
    pendingAction: pendingAction,
    withPendingAction: withPendingAction,
    visibleSections: visibleSections,
    sectionDevices: sectionDevices
  }
}
