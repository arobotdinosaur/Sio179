import serial
import time

# Open serial port
ser = serial.Serial('/dev/tty.usbserial-B000VAYU', 9600, timeout=1)  # Replace with correct port

def send_command(command):
    ser.write((command + '\r\n').encode())  # Send the command 
    ser.flushInput()
    ser.flushOutput()
    ser.write(command.encode())
    time.sleep(0.25)  # Wait for response
    response = ser.read_all().decode()  # Read the response
    print(response)

# Wake up the sensor
#send_command('\r\n')

# Poll for a single sample
send_command('TS')

# Close the serial connection
ser.close()
