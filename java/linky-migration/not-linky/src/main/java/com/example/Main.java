package com.example;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java -jar ascii-converter.jar <image-path> [width] [height]");
            System.exit(1);
        }

        String imagePath = args[0];
        int width = 100;  // Default width
        int height = 50;  // Default height

        if (args.length >= 3) {
            try {
                width = Integer.parseInt(args[1]);
                height = Integer.parseInt(args[2]);
            } catch (NumberFormatException e) {
                System.err.println("Invalid width or height. Using default values.");
            }
        }

        try {
            BufferedImage image = ImageIO.read(new File(imagePath));

            if (image == null) {
                System.err.println("Error: Could not load the image. Please check the file path.");
                System.exit(1);
            }

            String asciiArt = AsciiConverter.convertToAscii(image, width, height);
            System.out.println(asciiArt);

        } catch (IOException e) {
            System.err.println("Error loading image: " + e.getMessage());
        }

        String userName = System.getProperty("user.name");
        String osName = System.getProperty("os.name");
        String osVersion = System.getProperty("os.version");
        String osArchitecture = System.getProperty("os.arch");

        System.out.println("User Name: " + userName);
        System.out.println("Operating System Name: " + osName);
        //System.out.println("Operating System Version: " + osVersion);
        System.out.println("Operating System Architecture: " + osArchitecture);               
    }
}
