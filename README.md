# CCLogin

You should install luasocket first:

	opkg install luascoket

Get your secret by enter following command to your browser address bar.
Make sure you have already input your password in the password input box.

	javascript:alert(RSAUtils.encryptedString(publickey, encodeURIComponent($("#userPassword").val())));void(0);

Put `user.json` near cclogin.lua:

	{"username": "010203040506", "password": "your secret here"}

Copy all files to your router, run:

	lua cclogin.lua login
	lua cclogin.lua logout
