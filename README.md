# Websphere-Liberty-
This repository contains configuration, deployment scripts, and installation procedures for WebSphere Liberty. Features include custom port settings, clustering for high availability, SSL certificate integration, automated deployment scripts, and a step-by-step installation guide for a secure and scalable setup.

====================================================================================================================================================================

Websphere Default page with custom ports 
http port = 9000
https = 9001

Configuration required in server.xml : 

  <?xml version="1.0" encoding="UTF-8"?>
  <server description="new server">
  
      <!-- Enable features -->
      <featureManager>
          <feature>webProfile-8.0</feature>
      </featureManager>
  
      <!-- To access this server from a remote client add a host attribute to the following element, e.g. host="*" -->
      <httpEndpoint id="defaultHttpEndpoint"
                    host="*"
                    httpPort="9000"
                    httpsPort="9001" />
                    
      <!-- Automatically expand WAR files and EAR files -->
      <applicationManager autoExpand="true"/>

</server>


Snapshot : 

![Image](https://github.com/user-attachments/assets/923606ea-65ca-4f03-b0c9-fc78b972eeec)
