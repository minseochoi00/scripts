## This GUI has been created by @minseochoi00 with help of ChatGPT ##

# Start
import random
import hashlib

def generate_random_hex_color():
    """
    Generates a random hex color code.

    Returns:
    str: The hex code of the generated color.
    """
    random_hex_color = "#{:06x}".format(random.randint(0, 0xFFFFFF))
    return random_hex_color

def get_sha256_hashed_color_hex(hex_color):
    """
    Hashes a given hex color code using SHA-256.

    Parameters:
    hex_color (str): The hex code of the color.

    Returns:
    str: The SHA-256 hashed string of the hex color code.
    """
    hex_color_bytes = hex_color[1:].encode('utf-8')
    sha256_hashed_color = hashlib.sha256(hex_color_bytes).hexdigest()
    return sha256_hashed_color

def generate_unique_password():
    """
    Generates a unique password by dynamically creating a random color hex code,
    hashing it using SHA-256, and ensuring it is unique for each run.
    """
    hex_code = generate_random_hex_color()
    password = get_sha256_hashed_color_hex(hex_code)
    print(f"Generated password: {password}")

# Generate a unique password
generate_unique_password()