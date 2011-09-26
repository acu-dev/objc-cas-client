CAS Client
=========

This app demonstrates use of the CAS.h/CAS.m class to authenticate a user with a given CAS server and various services. The process begins by authenticating a user with a CAS server and request a TGT (ticket granting ticket). The TGT can then be used to request an ST (service ticket) for individual services. Services that are correctly configured with the CAS filters will validate the ST against the CAS server and grant access.

Implemntation
-------------------

Copy the CAS.h and CAS.m files into your app and use similar to the example app here.

Note
------

This app has not been worked on in quite a while. Feel free to contribute back to it or make suggestions.