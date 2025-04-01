//
//  ColorPickerView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/31/25.
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var hexColor: String
    
    var onSave: (Color, String) -> Void
    var onCancel: () -> Void
    
    @State private var red: Double = 0
    @State private var green: Double = 0
    @State private var blue: Double = 0
    
    init(selectedColor: Binding<Color>, hexColor: Binding<String>, onSave: @escaping (Color, String) -> Void, onCancel: @escaping () -> Void) {
        self._selectedColor = selectedColor
        self._hexColor = hexColor
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize RGB values from the selected color
        let components = UIColor(selectedColor.wrappedValue).cgColor.components ?? [0, 0, 0, 0]
        _red = State(initialValue: Double(components[0]))
        _green = State(initialValue: components.count > 2 ? Double(components[1]) : 0)
        _blue = State(initialValue: components.count > 2 ? Double(components[2]) : 0)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Color preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor)
                    .frame(height: 100)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                
                // Hex color display
                HStack {
                    Text("Hex:")
                        .font(.headline)
                    
                    TextField("Hex Color", text: $hexColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: hexColor) { newValue in
                            if let color = Color(hex: newValue) {
                                selectedColor = color
                                updateRGBFromColor(color)
                            }
                        }
                }
                .padding(.horizontal)
                
                // RGB sliders
                VStack(spacing: 15) {
                    colorSlider(value: $red, color: .red, label: "Red")
                    colorSlider(value: $green, color: .green, label: "Green")
                    colorSlider(value: $blue, color: .blue, label: "Blue")
                }
                .padding(.horizontal)
                
                // Preset colors
                VStack(alignment: .leading) {
                    Text("Presets")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(presetColors, id: \.self) { colorHex in
                                Button(action: {
                                    hexColor = colorHex
                                    if let color = Color(hex: colorHex) {
                                        selectedColor = color
                                        updateRGBFromColor(color)
                                    }
                                }) {
                                    Circle()
                                        .fill(Color(hex: colorHex) ?? .gray)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .shadow(radius: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedColor, hexColor)
                    }
                }
            }
            .onChange(of: red) { _ in updateColorAndHex() }
            .onChange(of: green) { _ in updateColorAndHex() }
            .onChange(of: blue) { _ in updateColorAndHex() }
        }
    }
    
    private func colorSlider(value: Binding<Double>, color: Color, label: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue * 255))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            Slider(value: value, in: 0...1)
                .accentColor(color)
        }
    }
    
    private func updateColorAndHex() {
        selectedColor = Color(red: red, green: green, blue: blue)
        hexColor = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
    
    private func updateRGBFromColor(_ color: Color) {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 0]
        red = Double(components[0])
        green = components.count > 2 ? Double(components[1]) : 0
        blue = components.count > 2 ? Double(components[2]) : 0
    }
    
    private let presetColors = [
        "#FF0000", // Red
        "#00FF00", // Green
        "#0000FF", // Blue
        "#FFFF00", // Yellow
        "#FF00FF", // Magenta
        "#00FFFF", // Cyan
        "#FFA500", // Orange
        "#800080", // Purple
        "#008000", // Dark Green
        "#000080", // Navy
        "#A52A2A", // Brown
        "#808080"  // Gray
    ]
}

// Extension to convert hex string to Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView(
            selectedColor: .constant(.blue),
            hexColor: .constant("#0000FF"),
            onSave: { _, _ in },
            onCancel: { }
        )
    }
}
