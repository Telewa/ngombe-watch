#define GPRS_TIMEOUT 12000 //in millisecods
#define GPRS_CONFIG_TIMEOUT 60000 //timeout the config after 1 minute and reboot
#define TCP_CONFIG_TIMEOUT 150000//tcp configuration timout* check this value

uint8_t noOfLines = 0; //no of times the data on the SD dard is written/cycles
uint8_t maxLoopsBeforeUpload = 10;
int timeDelayForRecording = 2000; //get data after every x seconds
uint8_t successSending=0;

char t[20];
uint8_t x = 0;//variable determines if successful or not
char  wholeString[300];
uint8_t gprsRetries=0;
int loopNo=0;
long stime;

void setup()
{
  USB.begin();
  //USB.println("USB port started...");

  // setup the GPS module
  USB.println("Setting up GPS...");

  GPS.ON();

  // waiting for GPS is connected to satellites
  while (!GPS.check())
  {
#ifdef DBG
    USB.println("Waiting for GPS connection");
#endif
    delay(1000);
  }

#ifdef DBG
  //USB.println("Connected");
#endif
}

void loop()
{  
  USB.print("Loop no: ");
  USB.println(loopNo++);

  for (noOfLines = 0; noOfLines < maxLoopsBeforeUpload; noOfLines++)
  {
    getValues();

    USB.println(wholeString);

    writeToFile(wholeString);

    delay(timeDelayForRecording);
  }
  USB.println("Sleeping for 2 seconds before uploading data...");
  delay(2000);

  uploadData();
  delay(5000);//should remove this delay
}

void getValues()
{
  //construct the json string
  sprintf(wholeString, "%s", "{");
  getAccelerometerReading();
  //USB.println("Got past acc");
  getGPS();
  //USB.println("Got past gps");
  getTemperature();
  //USB.println("Got past temp");
  getBatteryLevel();
  //USB.println("Got past batt");
  sprintf(wholeString + strlen(wholeString), "%s", "}\n");
  //USB.println("Got past all");
}

void getGPS()
{
  // open the uart
  USB.print("Memory before GPS connection = ");
  USB.println(freeMemory());
  GPS.begin();

  // Inits the GPS module
  GPS.init();

  // Checking for satellite connection
  while(!GPS.check())
  {
    USB.println("Waiting 4 GPS");
    delay(1000);
  }
  USB.print("Memory after GPS connection = ");
  USB.println(freeMemory());

  GPS.getPosition();
  USB.print("Memory after GPS get position = ");
  USB.println(freeMemory());

  //USB.println("---------------");
  sprintf(wholeString + strlen(wholeString), "%s", "\"tm\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.timeGPS);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"dt\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.dateGPS);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"lt\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.latitude);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"ln\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.longitude);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"al\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.altitude);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"sp\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.speed);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  sprintf(wholeString + strlen(wholeString), "%s", "\"cs\":\"");
  sprintf(wholeString + strlen(wholeString), "%s", GPS.course);
  sprintf(wholeString + strlen(wholeString), "%s", "\",");

  // Closing UART
  GPS.close();
}

// Show the remaining battery level

void getBatteryLevel()
{
  sprintf(wholeString + strlen(wholeString), "%s", "\"battery\":");
  sprintf(wholeString + strlen(wholeString), "%d",PWR.getBatteryLevel());
  sprintf(wholeString + strlen(wholeString), "%s", ",");

  // Show the battery Volts
  sprintf(wholeString + strlen(wholeString),"%s","\"battery (Volts)\":");
  Utils.float2String(PWR.getBatteryVolts(),t, 4);
  sprintf(wholeString + strlen(wholeString),"%s",t);
}

void getTemperature()
{
  int x_acc = RTC.getTemperature();

  sprintf(wholeString+strlen(wholeString),"%s", "\"temp\":");
  sprintf(t, "%d", x_acc);
  sprintf(wholeString+strlen(wholeString),"%s", t);
  sprintf(wholeString+strlen(wholeString),"%s",",");
}

void getAccelerometerReading()
{
  ACC.ON(); //put on the accelerometer
  byte check = ACC.check();
  if (check != 0x3A)
  {
    //USB.print(": Warning: Accelerometer not ok!\n");
    //USB.println(check, HEX);
  }
  else
  {
    //----------X Values-----------------------
    //format: {"ax":131,"ay":-19,"az":983} 
    sprintf(wholeString + strlen(wholeString), "%s", "\"ax\":");
    sprintf(wholeString + strlen(wholeString), "%d", ACC.getX());
    sprintf(wholeString + strlen(wholeString), "%s", ",");
    //----------Y Values-----------------------

    sprintf(wholeString + strlen(wholeString), "%s", "\"ay\":");
    sprintf(wholeString + strlen(wholeString), "%d", ACC.getY());
    sprintf(wholeString + strlen(wholeString), "%s", ",");

    //----------Z Values-----------------------
    sprintf(wholeString + strlen(wholeString), "%s", "\"az\":");
    sprintf(wholeString + strlen(wholeString), "%d", ACC.getZ());
    sprintf(wholeString + strlen(wholeString), "%s", ",");
  }
  ACC.close(); //put off the accelerometer
}

void getCellTowerDetails()
{
  //its own json string
  if(GPRS_Pro.getCellInfo() == 1)
  {
    //USB.println("Got cell tower connection...");

    sprintf(wholeString,"%s","{\"RSSI\":");
    sprintf(wholeString + strlen(wholeString),"%d",GPRS_Pro.RSSI);
    sprintf(wholeString + strlen(wholeString),"%s", ",");

    sprintf(wholeString + strlen(wholeString),"%s","\"Cell ID\":");
    sprintf(wholeString + strlen(wholeString),"%d", GPRS_Pro.cellID);
    sprintf(wholeString + strlen(wholeString),"%s", "}");
  }
  else// in case it didnt find, the string should not sill contail previous data
  {
    //USB.println("I didn't get cell tower connection...");

    sprintf(wholeString,"%s","{\"RSSI\":");
    sprintf(wholeString + strlen(wholeString),"%s","NULL");
    sprintf(wholeString + strlen(wholeString),"%s", ",");

    sprintf(wholeString + strlen(wholeString),"%s","\"Cell ID\":");
    sprintf(wholeString + strlen(wholeString),"%s","NULL");
    sprintf(wholeString + strlen(wholeString),"%s", "}");
  }
}

uint8_t writeToFile(char *value)
{
  x=0;//start when the value of x =0;
  /*
    Error codes
   1 if the writing/appending was successful
   -1 if unsuccessful writing.
   -3 if error appending
   -5 Folder doesnt exist but not created
   */

  SD.ON();

  if (SD.isFile("raw_data1.txt") == 1)
  {
    //USB.println("File already exixts");

    if (SD.appendln("raw_data1.txt", value) == 1)
    {
      //USB.println("appending successful");
      x = 1; //append successful
    }
    else
    {
      //USB.println("Could not write to the already existing file!");
      x = -3; //unsuccessful- could not append to that file 
    }
  }
  else
  {
    //USB.println("File does not exist. Creating it..");
    if (SD.create("raw_data1.txt"))
    {
      //USB.println("File creation successful");
      if (SD.writeSD("raw_data1.txt", value, 0))
      {
        //USB.println("writing successful");
        x = 1; //write successful
      }
      else
      {
        x = -1; //unsuccessful- could not write to that file  
        //USB.println("Could not write to the just created file!");
      }
    }
  }
  SD.OFF();
  return x;
}

void uploadData()
{
  SD.ON();

  if (SD.isFile("raw_data1.txt"))
  {
    SD.OFF();

    // Configure GPRS Connection
    stime = millis();
    while (!startGPRS() && ((millis() - stime) < GPRS_CONFIG_TIMEOUT))
    {
      USB.println("Trying to configure GPRS...");
      delay(2000);
      if (millis() - stime < 0) stime = millis();
    }

    // If timeout, exit. if not, try to upload
    if (millis() - stime > GPRS_CONFIG_TIMEOUT)
    {
#ifdef DBG
      USB.println("timeout: GPRS_CONFIG failed");
      PWR.reboot();
#endif
    }
    else
    {      
      USB.println("All GPRS OK now. sleep(3)");
      delay(3000);

      //config tcp connection 
      stime = millis();
      while((millis()-stime) < TCP_CONFIG_TIMEOUT)
      {
        if(!GPRS_Pro.configureGPRS_TCP_UDP(SINGLE_CONNECTION,NON_TRANSPARENT))
        {
          USB.print("Trying to configure TCP connection: ");
          USB.println(freeMemory());

          delay(6000);
        }
        else{
          break;
        }
      }

      if (millis() - stime > TCP_CONFIG_TIMEOUT)
      {
        USB.println("TCP config failed");
        PWR.reboot();
      }
      //end config tcp connection 

      else
      {
        USB.print("Configured OK. \nIP dir: ");
        USB.println(GPRS_Pro.IP_dir);

        //only try opening tcp connection if config was OK.
        USB.print("Opening TCP socket...");
        if (GPRS_Pro.createSocket(TCP_CLIENT, "54.235.113.108", "8081"))
        { // * should be replaced by the desired IP direction and $ by the port
          USB.println("Connected");

          //only try sending string if connected to tcp server
          USB.println("Sending data string...");
          SD.ON();

          USB.println("Memory status before uploading data");
          USB.println(freeMemory());
          for (int i = 0; i < SD.numln("raw_data1.txt"); i++)
          {

            //if(strcmp(text,"Sent")!=0)// do not send data that has already been sent
            //{
            if (GPRS_Pro.sendData(SD.catln("raw_data1.txt", i, 1)))
            {
              USB.print(i);
              USB.println(": Sent");
              //now delete the line by writing an 'sent' on that position
              //SD.writeSD("raw_data1.txt","sent", i);
              successSending=1;
            }
            else
            {
              USB.println("Failed sending");// if one fails, then the rest are bound to fail as well.
              successSending=0;
              break;
            }
            //            }
            //            else
            //            {
            //               USB.println("data already sent to server"); 
            //            }
          }
          USB.print("Memory status after uploading data: ");
          USB.println(freeMemory());

          SD.OFF();

//          USB.print("Memory status after SD card off: ");
//          USB.println(freeMemory());
          if(successSending==1)//if any string is not sent for whatever reason, do not delete the file
          {
        USB.print("Memory status before getting cell tower details: ");
          USB.println(freeMemory());
            getCellTowerDetails();
            USB.println(wholeString);//cell tower details
          USB.print("Memory status after getting the cell tower: ");
          USB.println(freeMemory());

            //wholeString now contains cell tower info(RSSI and CellId) tells the server to end the connection on his side
            if (GPRS_Pro.sendData(wholeString))
            {
              USB.print("Sent cell tower details. Memory: ");
              USB.println(freeMemory());
            }
            else
            {
              USB.println("Failed sending cell tower details. Memory: ");
              USB.println(freeMemory());
            }

            //'bye' tells the server to end the connection on his side
            if (GPRS_Pro.sendData("bye"))
            {
              USB.println("Sent");
            }
            else
            {
              USB.println("Failed sending");
            }
            //end closing string

            // Close socket
            USB.print("Closing TCP socket...");
            if (GPRS_Pro.closeSocket())
            {
              USB.println("Closed");
            }
            else
            {
              USB.println("Failed closing"); //if fails here, check server closing algorithm
            }

            SD.ON();
            //after upload, delete the uploaded file
            if (SD.del("raw_data1.txt"))
            {
              //USB.println("File deleted");
            }
            else
            {
              //USB.println("File could not deleted");
            }
            // Close GPRS Connection after upload
            GPRS_Pro.OFF();
          }
          SD.OFF();
        }
        else
        {
          USB.println("Error opening the socket"); // will simply go on but append to that file- server error
        }
      }
    }
  }
  else
  {
    //USB.println("file not there");
  }
}

//if this phase does not succeed, cellInfo will never return true
uint8_t startGPRS()
{
  x=0;//start when the value of x =0;

  // setup for GPRS_Pro serial port
  GPRS_Pro.ON();
  USB.println("GPRS_Pro module ready...");

  // waiting while GPRS_Pro connects to the network
  stime = millis();

  USB.print("Memory before attempting gprs connection: ");
  USB.println(freeMemory());
  while(millis()-stime < GPRS_TIMEOUT)
  {
    if(!GPRS_Pro.check())
    {
      USB.print("Trying to configure GPRS connection: Free Memory = ");
      USB.println(freeMemory());

      delay(2000);
    }
    else
    {
      break; 
    }
  }
  USB.print("Memory b4 attempting gprs connection: ");
  USB.println(freeMemory());

  // If timeout, exit. if not, try to upload
  if (millis() - stime > TCP_CONFIG_TIMEOUT)
  {
    USB.print("timeout: GPRS failed.Memory: ");
    USB.println(freeMemory());
    x=0;
  }
  else
  {
    USB.print("connected: Memory status");
    USB.println(freeMemory());
    x=1;
  }
  return x;
}