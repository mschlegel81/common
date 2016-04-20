{ This file was automatically created by Lazarus. Do not edit!
  This Source is only used to compile and install the package.
 }

UNIT laz_synapse;

INTERFACE

USES
    asn1util, blcksock, clamsend, dnssend, ftpsend, ftptsend, httpsend,
  imapsend, ldapsend, mimeinln, mimemess, mimepart, nntpsend, pingsend,
  pop3send, slogsend, smtpsend, snmpsend, sntpsend, synachar, synacode,
  synacrypt, synadbg, synafpc, synaicnv, synaip, synamisc, synaser, synautil,
  synsock, tlntsend, LazarusPackageIntf;

IMPLEMENTATION

PROCEDURE Register;
begin
end;

INITIALIZATION
  RegisterPackage('laz_synapse', @Register);
end.
