
# Setup service principal for whole subscription

## >>> Via Azure Portal

### >>> Go to AAD
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-36-51.png)

</div>

### >>> App Registrations
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-37-14.png)

</div>

### >>> new registration -> ...
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-37-47.png)

</div>

### >>> Grab `AAD_CLIENT_ID` and `ADD_TENANT_ID`
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-08-14-29-15.png)

</div>

### >>> Create secret and save as `AAD_SECRET`
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-38-14.png)

</div>
<br>
<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-38-31.png)

</div>

### >>> Assign role to subscription to controll all resources in subscription:

<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-40-18.png)

</div>

### >>> Or assing role to Container Registry to controll only it:

<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-49-18.png)

</div>

### >>> Here set service principal as Owner

<div style="background-color: black; text-align: center; padding-top: 20px; padding-right: 20px; padding-bottom: 5px; padding-left: 20px;">

![](images/README/2021-04-06-22-45-43.png)

</div>

