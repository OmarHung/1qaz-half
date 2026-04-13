#!/usr/bin/env swift
import AppKit
import Foundation

// MARK: - App Icon (1024x1024)

func drawAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }
    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.225

    // ── 漸層背景 ──────────────────────────────────────────────────────
    let cs = CGColorSpaceCreateDeviceRGB()
    let topColor    = CGColor(colorSpace: cs, components: [0.22, 0.28, 0.60, 1.0])!
    let bottomColor = CGColor(colorSpace: cs, components: [0.07, 0.09, 0.22, 1.0])!
    let gradient = CGGradient(colorsSpace: cs,
                              colors: [topColor, bottomColor] as CFArray,
                              locations: [0.0, 1.0])!

    let bgPath = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: size * 0.25, y: size),
                           end:   CGPoint(x: size * 0.75, y: 0),
                           options: [])
    ctx.restoreGState()

    // ── 頂部亮面（玻璃感）──────────────────────────────────────────────
    let glassRect  = CGRect(x: size*0.08, y: size*0.54, width: size*0.84, height: size*0.38)
    let glassPath  = CGPath(roundedRect: glassRect,
                            cornerWidth: corner * 0.6, cornerHeight: corner * 0.6,
                            transform: nil)
    let glassTop    = CGColor(colorSpace: cs, components: [1, 1, 1, 0.12])!
    let glassBottom = CGColor(colorSpace: cs, components: [1, 1, 1, 0.00])!
    let glassGrad   = CGGradient(colorsSpace: cs,
                                 colors: [glassTop, glassBottom] as CFArray,
                                 locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(glassPath)
    ctx.clip()
    ctx.drawLinearGradient(glassGrad,
                           start: CGPoint(x: size/2, y: glassRect.maxY),
                           end:   CGPoint(x: size/2, y: glassRect.minY),
                           options: [])
    ctx.restoreGState()

    // ── 主字「半」──────────────────────────────────────────────────────
    let para = NSMutableParagraphStyle()
    para.alignment = .center

    let mainFontSize = size * 0.56
    let mainFont = NSFont(name: "PingFangTC-Semibold", size: mainFontSize)
        ?? NSFont.boldSystemFont(ofSize: mainFontSize)

    let shadow = NSShadow()
    shadow.shadowColor  = NSColor(white: 0, alpha: 0.45)
    shadow.shadowBlurRadius = size * 0.05
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.025)

    let mainAttrs: [NSAttributedString.Key: Any] = [
        .font:            mainFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle:  para,
        .shadow:          shadow
    ]
    let mainStr  = NSAttributedString(string: "半", attributes: mainAttrs)
    let strSize  = mainStr.size()
    mainStr.draw(at: NSPoint(x: (size - strSize.width) / 2,
                             y: size * 0.22))

    // ── 副標「形」──────────────────────────────────────────────────────
    if size >= 64 {
        let subFontSize = size * 0.155
        let subFont = NSFont(name: "PingFangTC-Light", size: subFontSize)
            ?? NSFont.systemFont(ofSize: subFontSize, weight: .light)
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font:            subFont,
            .foregroundColor: NSColor(white: 1.0, alpha: 0.50),
            .paragraphStyle:  para
        ]
        NSString("形").draw(in: NSRect(x: 0, y: size * 0.065, width: size, height: size * 0.25),
                            withAttributes: subAttrs)
    }

    return image
}

// MARK: - 選單列 Template Icon

func drawMenuBarIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let para = NSMutableParagraphStyle()
    para.alignment = .center

    // 外框鍵盤鍵形狀
    let padding: CGFloat = size * 0.06
    let borderRect = NSRect(x: padding, y: padding,
                            width: size - padding*2, height: size - padding*2)
    let keyPath = NSBezierPath(roundedRect: borderRect,
                               xRadius: size * 0.18, yRadius: size * 0.18)
    keyPath.lineWidth = size * 0.10
    NSColor.black.setStroke()
    keyPath.stroke()

    // 「半」字填入，垂直置中
    let font = NSFont(name: "PingFangTC-Medium", size: size * 0.58)
        ?? NSFont.systemFont(ofSize: size * 0.58, weight: .medium)
    let attrs: [NSAttributedString.Key: Any] = [
        .font:            font,
        .foregroundColor: NSColor.black,
        .paragraphStyle:  para
    ]
    let str     = NSAttributedString(string: "半", attributes: attrs)
    let strSize = str.size()
    let drawPt  = NSPoint(x: (size - strSize.width) / 2,
                          y: (size - strSize.height) / 2)
    str.draw(at: drawPt)

    image.isTemplate = true
    return image
}

// MARK: - 工具函式

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff   = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data   = bitmap.representation(using: .png, properties: [:]) else {
        print("✗ 無法儲存 \(path)"); return
    }
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("✓ \(path)")
    } catch {
        print("✗ \(error.localizedDescription)")
    }
}

// MARK: - 執行

let fm  = FileManager.default
let dir = fm.currentDirectoryPath

// 1. App iconset
let iconsetPath = "\(dir)/AppIcon.iconset"
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16",      16),  ("icon_16x16@2x",    32),
    ("icon_32x32",      32),  ("icon_32x32@2x",    64),
    ("icon_128x128",   128),  ("icon_128x128@2x", 256),
    ("icon_256x256",   256),  ("icon_256x256@2x", 512),
    ("icon_512x512",   512),  ("icon_512x512@2x", 1024)
]
for (name, size) in iconSizes {
    savePNG(drawAppIcon(size: size), to: "\(iconsetPath)/\(name).png")
}

// 2. 轉成 .icns
let icnsPath = "\(dir)/Sources/KeysHelper/Resources/AppIcon.icns"
try? fm.createDirectory(atPath: "\(dir)/Sources/KeysHelper/Resources",
                        withIntermediateDirectories: true)

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments     = ["-c", "icns", iconsetPath, "-o", icnsPath]
try? iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "✓ AppIcon.icns" : "✗ iconutil 失敗")

// 3. 選單列 template icon
let resDir = "\(dir)/Sources/KeysHelper/Resources"
savePNG(drawMenuBarIcon(size: 22),  to: "\(resDir)/menubar.png")
savePNG(drawMenuBarIcon(size: 44),  to: "\(resDir)/menubar@2x.png")

// 4. 清除 iconset 暫存
try? fm.removeItem(atPath: iconsetPath)
print("\n完成！圖示已輸出至 Sources/KeysHelper/Resources/")
