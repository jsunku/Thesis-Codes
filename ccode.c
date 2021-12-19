#include "xparameters.h"

#include "xstatus.h"

#include "xuartlite.h"

#include "xparameters.h"

#include "xstatus.h"

#include "xuartlite.h"

#include "xil_printf.h"

#include <stdio.h>

#include <stdlib.h>

#include <string.h>

#include <sleep.h>

#include <math.h>

#include "xgpio.h"

#include "synchronization.h"

#include "xbasic_types.h"

#define UARTLITE_DEVICE_ID XPAR_AXI_UARTLITE_1_DEVICE_ID
#define synchro(k)( * (volatile unsigned int * )(XPAR_SYNCHRONIZATION_0_S00_AXI_BASEADDR + 4 * k))
#define Max_Buffer_Size 16
#define Table_Size 360000 // for 0.01 omega
#define PI 3.1415926535897932

static float cos_array[Table_Size];
static float sin_array[Table_Size];

// function prototypes
int StartRotaryAxis(u16 DeviceId);
int send_scannercoordinates();
int sendCommandAndWaitForResponse(char * cmd, char * response);

XUartLite UartLite; /* Instance of the UartLite Device*/
u8 SendBuffer[Max_Buffer_Size]; /* Buffer for Transmitting Data */
u8 RecvBuffer[Max_Buffer_Size]; /* Buffer for Receiving Data */

// Two gpio's initialization for sending scanner coordinates
XGpio output;
XGpio output1;

char response[Max_Buffer_Size];

static void Table_init() {

  for (int i = 0; i < Table_Size; ++i) {
    float angle = (i * 2.0 * PI) / Table_Size; // eg: i =1 then 2pi/ 360000 = 1.745 //scallig factor b/w int anf float (i is index)
    cos_array[i] = cos(angle);
    sin_array[i] = sin(angle);
  }
}

static float Table_cos(float angle) // replacemenr for cos calculation
{

  int i = angle / (2.0 * PI) * Table_Size; // float to integer conversion
  return cos_array[i];
}

static float Table_sin(float angle) // replacement for sin calculation
{

  int i = angle / (2.0 * PI) * Table_Size; // float to integer conversion
  return sin_array[i];
}

int main(void) {
  int Status, Scanner_Status;

  // function for starting rotary axis
  Table_init();
  Status = StartRotaryAxis(UARTLITE_DEVICE_ID);
  if (Status != XST_SUCCESS) {
    xil_printf("StartRotaryAxis failed\r\n");

  }

  // function for sending scanner coordinates
  Scanner_Status = send_scannercoordinates();

  if (Scanner_Status != XST_SUCCESS) {
    xil_printf("send_scannercoordinates Failed\r\n");
  }

  sendCommandAndWaitForResponse("t 0\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  return 0;
  // function for stopping rotary axis
}

int sendCommandAndWaitForResponse(char * cmd, char * response) {
  int Index;
  int ret = 0;
  int cmd_length;

  cmd_length = strlen(cmd);
  for (Index = 0; Index < cmd_length; Index++) {
    RecvBuffer[Index] = 0;
  }

  int SentCount = 0;

  for (Index = 0; Index < cmd_length; Index++) {
    SentCount += XUartLite_Send( & UartLite, (u8 * ) & cmd[SentCount], 1); // heredereferncing the pointer(u8*)& so at the end it means just cmd[sentcount].sending one ne byte and                                                                    copy into us cmd array
    usleep(5000);
  } // because uart hardware buffer is 16bytes here sometimes we are sending 17 bytes so one  by one through fifo.
  if (SentCount != cmd_length) {
    return XST_FAILURE;
  }

  int ReceivedCount = 0;
  while (1) {
    int ret = XUartLite_Recv( & UartLite, RecvBuffer + ReceivedCount, Max_Buffer_Size - ReceivedCount); //  1 or TEST_BUFFER_SIZE - ReceivedCount...modified and
    //1 meaning receive only one charecter at a time
    if (ret == 0)
      break;
  }

  ReceivedCount = ReceivedCount + ret;

  if (ReceivedCount == Max_Buffer_Size) /// check this
  {
    exit(1);
  }

  /*
   * Check the receive buffer data against the send buffer and verify the
   * data was correctly received.
   */
  // Alternattive: strcmp();
  strcpy(response, (char * ) RecvBuffer); // copy the receive buffer into response

  return XST_SUCCESS;

}

// calling start rotary axis function
int StartRotaryAxis(u16 DeviceId) {
  int Status;
  char response[Max_Buffer_Size];
  Status = XUartLite_Initialize( & UartLite, DeviceId);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }
  Status = XUartLite_SelfTest( & UartLite);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }

  // Executuing Homing Sequence(Homing method)

  //Sets the homing method to use the next index pulse as home.
  sendCommandAndWaitForResponse("s r0xc2 544\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }
  //Sets the slow velocity to 4000 counts/second.
  sendCommandAndWaitForResponse("s r0xc4 400000\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }
  //Sets the home offset to 1000 counts.  
  sendCommandAndWaitForResponse("s r0xc6 1000\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }
  // Enables the drive in programmed position mode.
  sendCommandAndWaitForResponse("s r0x24 21\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }
  //Starts the homing sequence
  sendCommandAndWaitForResponse("t 2\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  // delay before executuing in the position mode
  usleep(200000);

  //Set the trajectory generator to velocity move
  sendCommandAndWaitForResponse("s r0xc8 2\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  //Set the position command to velocity move with positive direction

  sendCommandAndWaitForResponse("s r0xca 1\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  // maximum velocity to 36000 counts/second.

  sendCommandAndWaitForResponse("s r0xcb 360000\r", response); ///buffer size check
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;

  }

  // Set maximum acceleration to 200000 counts/second2
  sendCommandAndWaitForResponse("s r0xcc 20000\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  //Set maximum deceleration to 200000 counts/second2.
  sendCommandAndWaitForResponse("s r0xcd 20000\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  //Enable the drive in Programmed Position (Trajectory Generator) Mode

  sendCommandAndWaitForResponse("s r0x24 21\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;

  }

  //Read actual position. Example displays an actual position of 0.

  sendCommandAndWaitForResponse("g r0x32 \r", response);
  if (response[0] != 118) //"v")
  {
    return XST_FAILURE;
  } else {
    currentPosition = (int) atoi( & response[2]); // covert response string into integer.

  }

  (void) currentPosition;

  //Execute the move.
  sendCommandAndWaitForResponse("t 1\r", response);
  if (!(strcmp(response, "ok\r") == 0)) {
    return XST_FAILURE;
  }

  return 0;
}

// calling sending coordinates for scanner function
int send_scannercoordinates()

{
  int Status, sync;
  int sync1, sync2;

  Status = XGpio_Initialize( & output, XPAR_AXI_GPIO_0_DEVICE_ID);
  if (Status != XST_SUCCESS) {
    xil_printf("Gpio Initialization Failed\r\n");
    return XST_FAILURE;
  }
  // configuring GPIO IP direction
  XGpio_SetDataDirection( & output, 1, 0x0000);
  XGpio_SetDataDirection( & output, 2, 0x0000); // here this address for chanel for setting as a output.
  float angle = 0.0; // Target angle will be continuously updated, in units of radians.
  float omega = (0.05) * (PI / 180); // stepsize for drwaning circles eg: if step size is 1 total steps are 360 for 1 circle
  float R = 10000.0; // Radius in 5 cm
  float x, y, temp_y;
  int loop_count = 163800;

  sync2 = synchro(2); // reading the slave registor

  //	while ((sync2 & 1) !=1) // TBD: want some kind of mechanism to exit the loop.

  while (loop_count > 0) {

    // Calculate X,Y coordinates based on current targent angle.
    //send = 1;
    x = R * Table_cos(angle);
    temp_y = R * Table_sin(angle);
    y = temp_y * (10.0 / 9.0);

    XGpio_DiscreteWrite( & output, 1, (int) x);
    XGpio_DiscreteWrite( & output, 2, (int) y);

    usleep(10);

    synchro(0) = (int)(angle / (2.0 * 3.14159 f) * (65535.0 f)); // Convert angle to integer range 65535( 0.005 degree per count)

    sync = synchro(0); // Read from synchronization IP slv_reg 0 (ctr_fa signals)

    sync1 = synchro(1); // Read from synchronization IP slv_reg 1 (ctr_sl signals)

    angle += omega; // Increment angle with step size

    //counter = synchro(1); previously used to check the counter value for rotation

    // Reading slv_reg 0 individual bits and based on the control signal adjusting the angle difference by subtracting the desired stepsize 

    if (sync & 1) // Is bit 0 true
    {
      angle -= 0.005 f * omega;
    }
    if (sync & 2) // Is bit 1 true
    {
      angle -= 0.020 f * omega;
    }
    if (sync & 4) {
      angle -= 0.025 f * omega;
    }
    if (sync & 8) {
      angle -= 0.030 f * omega;
    }
    if (sync & 16) {
      angle -= 0.035 * omega;
    }
    if (sync & 32) {
      angle -= 0.040 f * omega;
    }
    if (sync & 64) {
      angle -= 0.045 f * omega;
    }
    if (sync & 128) {
      angle -= 0.045 f * omega;
    }
    if (sync & 256) {
      angle -= 0.049 f * omega;
    }
    if (sync & 512) {
      angle -= 0.050 f * omega;
    }

    // Reading slv_reg 1 individual bits and based on the control signal adjusting the angle difference by adding the desired stepsize 
    if (sync1 & 1)

    {
      angle += 0.005 f * omega; // Is bit 0 true
    }
    if (sync1 & 2) {
      angle += 0.020 f * omega; // Is bit 1 true
    }
    if (sync1 & 4) {
      angle += 0.025 f * omega;
    }
    if (sync1 & 8) {
      angle += 0.030 f * omega;
    }
    if (sync1 & 16) {
      angle += 0.035 f * omega;
    }
    if (sync1 & 32) {
      angle += 0.040 f * omega;
    }
    if (sync1 & 64) {
      angle += 0.045 f * omega;
    }
    if (sync1 & 128) {
      angle += 0.045 f * omega;
    }
    if (sync1 & 256) {
      angle += 0.049 f * omega;
    }
    if (sync1 & 512) {
      angle += 0.050 f * omega;
    }

    if (angle >= 2.0 * 3.141592653589793 f) // after 1 rev it can go more than 360 so subtract the exra degree more than 360
      angle -= 2.0 * 3.141592653589793 f;

    loop_count--;

  }

  return 0;

}