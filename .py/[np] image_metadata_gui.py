import tkinter as tk
from tkinter import filedialog, Text
from PIL import Image, ExifTags
from datetime import datetime
import os
import logging
import warnings

# Step 1: Configure logging
logging.basicConfig(
    level=logging.WARNING,  # Only log warnings, errors, and critical messages
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler()  # Log to the console
    ]
)

# Step 2: Suppress less critical warnings
# Redirect non-critical warnings to a log file or ignore them
def warning_filter(message, category, filename, lineno, file=None, line=None):
    if issubclass(category, UserWarning):
        return  # Ignore UserWarnings or handle them differently if needed
    else:
        logging.warning(f"{filename}:{lineno}: {category.__name__}: {message}")

warnings.showwarning = warning_filter
warnings.simplefilter("ignore", UserWarning)  # Ignore user-level warnings, only log critical ones

# Step 3: Utility functions for GPS and Date/Time format conversion
def dms_to_decimal(degrees, minutes, seconds, direction):
    """Convert GPS coordinates from DMS to decimal format."""
    decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
    if direction in ['S', 'W']:
        decimal *= -1
    return decimal

def format_gps_coordinates(gps_data, ref):
    """Format and convert raw GPS data to a human-readable string."""
    degrees = float(gps_data[0])
    minutes = float(gps_data[1])
    seconds = float(gps_data[2])
    decimal = dms_to_decimal(degrees, minutes, seconds, ref)
    return f"{decimal} ({degrees}° {minutes}' {seconds}\" {ref})"

def convert_datetime_format(date_time_str):
    """Convert EXIF DateTime format to desired format."""
    # Parse the original EXIF DateTime string
    original_format = "%Y:%m:%d %H:%M:%S"
    dt_obj = datetime.strptime(date_time_str, original_format)

    # Convert it to the desired format
    new_format = "%Y/%m/%d %I:%M:%S %p"  # Desired format with 12-hour time and AM/PM
    return dt_obj.strftime(new_format)

# Step 4: Metadata extraction function
def extract_important_exif_data(exif_data):
    """Extract and return a dictionary of important EXIF data for diagnostics."""
    important_tags = {
        'DateTime': 'Date/Time',
        'Make': 'Device Make',  # Can be either camera or phone make
        'Model': 'Device Model',  # Can be either camera or phone model
        #'ExposureTime': 'Exposure Time',
        #'FNumber': 'Aperture',
        #'ISOSpeedRatings': 'ISO Speed',
        #'FocalLength': 'Focal Length'
    }
    important_data = {}
    for tag, value in exif_data.items():
        decoded = ExifTags.TAGS.get(tag, tag)
        if decoded in important_tags:
            if decoded == 'DateTime':  # Apply the DateTime conversion
                value = convert_datetime_format(value)
            important_data[important_tags[decoded]] = value
    return important_data

# Step 5: Image uploading and metadata display function
def upload_image():
    filename = filedialog.askopenfilename(initialdir="/", title="Select an Image",
                                          filetypes=(("Image files", "*.jpg *.jpeg *.png *.tiff *.bmp"), ("all files", "*.*")))
    if not filename:
        return
    try:
        img = Image.open(filename)
        exif_data = img._getexif()  # Extract EXIF data if available
        text_area.delete('1.0', tk.END)

        if exif_data:
            important_data = extract_important_exif_data(exif_data)
            for key, value in important_data.items():
                text_area.insert(tk.END, f"{key}: {value}\n")

            # Extract and display GPS data if available
            gps_info = exif_data.get(34853)  # 34853 is the tag for GPSInfo
            if gps_info and all(key in gps_info for key in (1, 2, 3, 4)):
                lat_ref = gps_info[1]
                lat_data = gps_info[2]
                lon_ref = gps_info[3]
                lon_data = gps_info[4]

                formatted_lat = format_gps_coordinates(lat_data, lat_ref)
                formatted_lon = format_gps_coordinates(lon_data, lon_ref)

                text_area.insert(tk.END, f"Latitude: {formatted_lat}\n")
                text_area.insert(tk.END, f"Longitude: {formatted_lon}\n")
            else:
                text_area.insert(tk.END, "GPS metadata not found.\n")
        else:
            text_area.insert(tk.END, "No metadata found.\n")
    except Exception as e:
        text_area.delete('1.0', tk.END)
        logging.error(f"Error: {str(e)}")
        text_area.insert(tk.END, f"Error: {str(e)}")

# Set up the GUI
root = tk.Tk()
root.title("Image Metadata Viewer")

frame = tk.Frame(root, padx=10, pady=10)
frame.pack(padx=10, pady=10)

upload_btn = tk.Button(frame, text="Upload Image", command=upload_image)
upload_btn.pack()

text_area = Text(frame, wrap="word")
text_area.pack(expand=True)

root.mainloop()
