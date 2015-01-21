// Functionality to send emails
// make sure the path is set to find the libcurl library.  You can use standard libs if required
// windows:
// set PATH=%PATH%;%KDBLIB%/w32
// linux:
// export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l[32|64]

\d .email

// configuration for default mail server
enabled:@[value;`enabled;.z.o in `w32`l32`l64`m32`m64]		// whether emails are enabled
url:@[value;`url;`]						// url of email server e.g. `$"smtp://mail.example.com:80"
user:@[value;`user;`]						// user account to use to send emails e.g. torq@aquaq.co.uk	
password:@[value;`password;`]					// password for user account
from:@[value;`from;`$"torq@localhost"]				// address for return emails e.g. torq@aquaq.co.uk
usessl:@[value;`usessl;0b]					// connect using SSL/TLS
debug:@[value;`debug;0i]					// debug level for email library: 0i = none, 1i=normal, 2i=verbose
img:@[value;`img;`$getenv[`KDBHTML],"/img/logo-email.png"]	// default image for bottom of email

lib:`$getenv[`KDBLIB],"/",string[.z.o],"/torQemail";
connected:@[value;`connected;0b]

if[.email.enabled;

  libfile:hsym ` sv lib,$[.z.o like "w*"; `dll; `so];
  libexists:not ()~key libfile;
  if[not .email.libexists; .lg.e[`email;"no such file ",1_string libfile]]; 
  if[.email.libexists;
  	connect:@[{x 2:(`emailConnect;1)};lib;{.lg.w[`init;"failed to create .email.connect ",x]}];
  	disconnect:@[{x 2:(`emailDisconnect;1)};lib;{.lg.w[`init;"failed to create .email.disconnect ",x]}];
  	send:@[{x 2:(`emailSend;1)};lib;{.lg.w[`init;"failed to create .email.send ",x]}];
  	create:@[{x 2:(`emailCreate;1)};lib;{.lg.w[`init;"failed to create .email.create ",x]}];
  	g:@[{x 2:(`emailGet;1)};lib;{.lg.w[`init;"failed to create .email.get ",x]}];
  	getSocket:@[{x 2:(`getSocket;1)};lib;{.lg.w[`init;"failed to create .email.getSocket ",x]}];
  ];
 ];

// connect to the configured default email server
connectdefault:{
 if[any null (url;user;password); .lg.e[`email; "url, user and password cannot be null"]]; 
 connected::`boolean$1+connect `url`user`password`from`usessl`debug!(url;user;password;from;usessl;debug);
 $[connected;.lg.o[`email;"connection to mail server successful"];
 	     .lg.e[`email;"connection to mail server failed"]]}

// send an email using the default mail server.  Try to establish a connection first
senddefault:{
 if[not enabled; .lg.e[`email;e:"email sending is not enabled"]; 'e];
 .lg.o[`email;"sending email"];
 if[not connected; connectdefault[]];
 if[not connected; .lg.e[`email; "cannot send email as no connection to mail server available"]];
 x[`body]:x[`body],defaultfooter[];
 res:send x,`image`debug!(img;debug);
 $[res>0;.lg.o[`email;"Email sent. size was ",(string res)," bytes"]; .lg.e[`email;"failed to send email"]];
 res} 

defaultfooter:{("";"email generated by proctype=",(string .proc.proctype),", procname=",(string .proc.procname)," running on ",(string .z.h)," at time ",(" " sv string `date`time$.z.p)," GMT")} 

test:{senddefault `to`subject`body!(x;"test email";enlist ("this is a test email to see if the TorQ email lib is configured correctly"))}

\

SIMPLE SEND:
.email.senddefault `to`subject`body!(`$"jim@aquaq.co.uk";"hi jim";("here's some stuff";"to think about"))
