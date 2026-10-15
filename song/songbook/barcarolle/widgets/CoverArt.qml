import QtQuick

// A picture painted the way the desktop paints the cover, shrunk to this item: cropped to fill, or,
// when `tile`, the pattern repeated at the size its tiles have on a `screenWidth`-wide screen (1:1 there).
Item {
    id: art

    property string source: ""
    property bool tile: false
    property real screenWidth: 1920
    property int cropWidth: 0
    readonly property real k: art.width / Math.max(1, art.screenWidth)

    clip: true

    Image {
        visible: !art.tile
        anchors.fill: parent
        source: art.tile ? "" : art.source
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: art.cropWidth
        asynchronous: true
    }
    Image {
        visible: art.tile
        width: art.width / Math.max(0.001, art.k)
        height: art.height / Math.max(0.001, art.k)
        scale: art.k
        transformOrigin: Item.TopLeft
        source: art.tile ? art.source : ""
        fillMode: Image.Tile
        asynchronous: true
    }
}
