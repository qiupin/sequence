import message;

showbox('UA-A');
showbox('SIP');
showbox('DB');
showbox('MS');
showbox('UA-B');

msg(1,2,'INVITE');
event(2,'routing');
msg(2,4,'RESERVE(clg, cld)');
msg(4,2,'ACK(clg:chn 1, cld:chn 2)');
info(2,3,'insert(session 1)');
info(2,3,'insert(sub session 1)');
msg(2,5,'INVITE');
msg(5,2,'180 Ring');
msg(2,1,'180 Ring');

event(5,'offhook');
rtp(5,4,type=2);
msg(5,2,'200 OK');
msg(2,4,'CONNECT(chn 1, chn 2)');
rtp(4,1,type=2);
msg(4,2,'ACK');
msg(2,4,'RECORD(name 1, chn 1, chn 2)');
msg(4,2,'ACK(mid 1)');
msg(2,4,'RECORD(name 2, chn 2, chn 2)');
msg(4,2,'ACK(mid 2)');
info(2,3,'update(sub session 1)');
info(2,3,'update(session 1)');
msg(2,1,'200 OK');
rtp(1,4);
rtp(4,5);

endmsg();
