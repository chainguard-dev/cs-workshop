package com.example;

import java.awt.*;
import java.awt.image.BufferedImage;

public class AsciiConverter {
    private static final char[] ASCII_CHARS = { '@', '#', 'S', '%', '?', '*', '+', ';', ':', ',', '.' };

    public static String convertToAscii(BufferedImage image, int width, int height) {
        // Resize the image
        BufferedImage resizedImage = resizeImage(image, width, height);
        StringBuilder asciiArt = new StringBuilder();

        for (int y = 0; y < resizedImage.getHeight(); y++) {
            for (int x = 0; x < resizedImage.getWidth(); x++) {
                Color color = new Color(resizedImage.getRGB(x, y));
                int brightness = (color.getRed() + color.getGreen() + color.getBlue()) / 3;
                int index = (brightness * (ASCII_CHARS.length - 1)) / 255;
                asciiArt.append(ASCII_CHARS[index]);
            }
            asciiArt.append("\n"); // New line for each row
        }

        return asciiArt.toString();
    }

    private static BufferedImage resizeImage(BufferedImage originalImage, int width, int height) {
        Image tmp = originalImage.getScaledInstance(width, height, Image.SCALE_SMOOTH);
        BufferedImage resized = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = resized.createGraphics();
        g2d.drawImage(tmp, 0, 0, null);
        g2d.dispose();
        return resized;
    }
}
