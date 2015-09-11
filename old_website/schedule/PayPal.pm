package PayPal;

# Borrowed from cpan's Business::PayPal

use 5.6.1;
use strict;
use warnings;

our $VERSION = '0.08';

use Net::SSLeay 1.14;
use Digest::MD5 qw(md5_hex);

our $Cert;
our $Certcontent;

my @certificates;
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIGSzCCBTOgAwIBAgIQLjOHT2/i1B7T//819qTJGDANBgkqhkiG9w0BAQUFADCB
ujELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2Ug
YXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykwNjE0MDIGA1UEAxMr
VmVyaVNpZ24gQ2xhc3MgMyBFeHRlbmRlZCBWYWxpZGF0aW9uIFNTTCBDQTAeFw0x
MTAzMjMwMDAwMDBaFw0xMzA0MDEyMzU5NTlaMIIBDzETMBEGCysGAQQBgjc8AgED
EwJVUzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDxMUUHJpdmF0
ZSBPcmdhbml6YXRpb24xEDAOBgNVBAUTBzMwMTQyNjcxCzAJBgNVBAYTAlVTMRMw
EQYDVQQRFAo5NTEzMS0yMDIxMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQH
FAhTYW4gSm9zZTEWMBQGA1UECRQNMjIxMSBOIDFzdCBTdDEVMBMGA1UEChQMUGF5
UGFsLCBJbmMuMRowGAYDVQQLFBFQYXlQYWwgUHJvZHVjdGlvbjEXMBUGA1UEAxQO
d3d3LnBheXBhbC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCd
szetUP2zRUbaN1vHuX9WV2mMq0IIVQ5NX2kpFCwBYc4vwW/CHiMr+dgs8lDduCfH
5uxhyRxKtJa6GElIIiP8qFB5HFWf1uUgoDPC1he4HaxUkowCnVEqjEowOy9R9Cr4
yyrmqmMEDccVsx4d3dOY2JF1FrLDHT7qH/GCBnyYw+nZJ88ci6HqnVJiNM+NX/D/
d7Y3r3V1bp7y1DaJwK/z/uMwNCC+lcM59w+nwAvLutgCW6WitFHMB+HpSsOSJlIZ
ydpj0Ox+javRR1FIdhRUFMK4wwcbD8PvULi1gM+sYsJIzP0mHDlhWRIDImG1zmy2
x7ZLp0HA5WayjI5aSn9fAgMBAAGjggHzMIIB7zAJBgNVHRMEAjAAMB0GA1UdDgQW
BBQxqt0MVbSO4lWE5aB52xc8nEq5RTALBgNVHQ8EBAMCBaAwQgYDVR0fBDswOTA3
oDWgM4YxaHR0cDovL0VWU2VjdXJlLWNybC52ZXJpc2lnbi5jb20vRVZTZWN1cmUy
MDA2LmNybDBEBgNVHSAEPTA7MDkGC2CGSAGG+EUBBxcGMCowKAYIKwYBBQUHAgEW
HGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEwHQYDVR0lBBYwFAYIKwYBBQUH
AwEGCCsGAQUFBwMCMB8GA1UdIwQYMBaAFPyKULqeuSVae1WFT5UAY4/pWGtDMHwG
CCsGAQUFBwEBBHAwbjAtBggrBgEFBQcwAYYhaHR0cDovL0VWU2VjdXJlLW9jc3Au
dmVyaXNpZ24uY29tMD0GCCsGAQUFBzAChjFodHRwOi8vRVZTZWN1cmUtYWlhLnZl
cmlzaWduLmNvbS9FVlNlY3VyZTIwMDYuY2VyMG4GCCsGAQUFBwEMBGIwYKFeoFww
WjBYMFYWCWltYWdlL2dpZjAhMB8wBwYFKw4DAhoEFEtruSiWBgy70FI4mymsSweL
IQUYMCYWJGh0dHA6Ly9sb2dvLnZlcmlzaWduLmNvbS92c2xvZ28xLmdpZjANBgkq
hkiG9w0BAQUFAAOCAQEAisdjAvky8ehg4A0J3ED6+yR0BU77cqtrLUKqzaLcLL/B
wuj8gErM8LLaWMGM/FJcoNEUgSkMI3/Qr1YXtXFvdqo3urqMhi/SsuUJU85Gnoxr
Vr0rWoBqOOnmcsVEgtYeusK0sQbxq5JlE1eq9xqYZrKuOuA/8JS1V7Ss1iFrtA5i
pwotaEK3k5NEJOQh9/Zm+fy1vZfUyyX+iVSlmyFHC4bzu2DlzZln3UzjBJeXoEfe
YjQyLpdUhUhuPslV1qs+Bmi6O+e6htDHvD05wUaRzk6vsPcEQ3EqsPbdpLgejb5p
9YDR12XLZeQjO1uiunCsJkDIf9/5Mqpu57pw8v1QNA==
-----END CERTIFICATE-----
CERT

push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIF9zCCBN+gAwIBAgIQE793e1MYa7/UOM7AWAq1djANBgkqhkiG9w0BAQUFADCB
ujELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2Ug
YXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykwNjE0MDIGA1UEAxMr
VmVyaVNpZ24gQ2xhc3MgMyBFeHRlbmRlZCBWYWxpZGF0aW9uIFNTTCBDQTAeFw0x
MjA3MjUwMDAwMDBaFw0xNDA3MjYyMzU5NTlaMIIBDTETMBEGCysGAQQBgjc8AgED
EwJVUzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDxMUUHJpdmF0
ZSBPcmdhbml6YXRpb24xEDAOBgNVBAUTBzMwMTQyNjcxCzAJBgNVBAYTAlVTMRMw
EQYDVQQRFAo5NTEzMS0yMDIxMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQH
FAhTYW4gSm9zZTEWMBQGA1UECRQNMjIxMSBOIDFzdCBTdDEVMBMGA1UEChQMUGF5
UGFsLCBJbmMuMRgwFgYDVQQLFA9Ib3N0aW5nIFN1cHBvcnQxFzAVBgNVBAMUDnd3
dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAppUu
PoT6YFWB8pFt8zRlOsXR9oiqkFI4QNwUw2P4n9XKsecMr6N41dbbKYz6jo1iwQRF
d1bF+Jhc8Me9LhSugvGmN0idSZkLKyGSC+npiVki28NBu7/bHjdM8A3Soj6r8z0w
VmhA7nyd0icIcPvtyK1lUA3oBw96B+RpA2q5WWXFkpFS7b0827rnJSy8Ymdmb3nb
7I2vMLNl+EP1oy6cXL+6hqRun7dJ2hBhf+PbXn82AOWry6kdaMh8lS7GaFhVi+3e
4MqBq7aAxB3dHTT0FE0nrcGDUKLi1G0mNZ3MC8kE73Gw4LOWbRSOwHwM6cKSYROJ
LW5h4RRoDumqqBcRLwIDAQABo4IBoTCCAZ0wGQYDVR0RBBIwEIIOd3d3LnBheXBh
bC5jb20wCQYDVR0TBAIwADAdBgNVHQ4EFgQU1jn61Uw9IMzAhBDGhhRQ272uHxgw
DgYDVR0PAQH/BAQDAgWgMEIGA1UdHwQ7MDkwN6A1oDOGMWh0dHA6Ly9FVlNlY3Vy
ZS1jcmwudmVyaXNpZ24uY29tL0VWU2VjdXJlMjAwNi5jcmwwRAYDVR0gBD0wOzA5
BgtghkgBhvhFAQcXBjAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy52ZXJpc2ln
bi5jb20vY3BzMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAfBgNVHSME
GDAWgBT8ilC6nrklWntVhU+VAGOP6VhrQzB8BggrBgEFBQcBAQRwMG4wLQYIKwYB
BQUHMAGGIWh0dHA6Ly9FVlNlY3VyZS1vY3NwLnZlcmlzaWduLmNvbTA9BggrBgEF
BQcwAoYxaHR0cDovL0VWU2VjdXJlLWFpYS52ZXJpc2lnbi5jb20vRVZTZWN1cmUy
MDA2LmNlcjANBgkqhkiG9w0BAQUFAAOCAQEAUuBmKY9TPpsM7OYaP6lu1Vu+koMp
vjr6rtj1CRqi3/LMRQv2IBiZgcvhJ4MtHlXlLX4/AZD7SlLi4ufPlcVCms7I53To
QcfdkDxjCPJ87yswfUWsrs/2r4I8Ov11hjEqrHtKYFeNylOEwY3ebXdUP0dKzF7T
ojUnh2wrXCQ209jm6z+XP0f90C9SuTe93gAv1PUhYISdvmjxnCLe5+yu3maQB4dV
+IwWEw0icKMfxU848hF/X2wqXd6pelXnox2eAFgW/OYm7kNrUvJxyvI+1YXAoQOG
yV9cU3oSGzyTfllBTZWTzvPT1rzG40AL3OQXk8qgWUKfpEhsZVAnMBa2Xg==
-----END CERTIFICATE-----
CERT

push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIGUzCCBTugAwIBAgIQQcO4g86BppQ1JLIKmUw/VDANBgkqhkiG9w0BAQUFADCB
ujELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2Ug
YXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykwNjE0MDIGA1UEAxMr
VmVyaVNpZ24gQ2xhc3MgMyBFeHRlbmRlZCBWYWxpZGF0aW9uIFNTTCBDQTAeFw0x
MTA5MDEwMDAwMDBaFw0xMzA5MzAyMzU5NTlaMIIBFzETMBEGCysGAQQBgjc8AgED
EwJVUzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDxMUUHJpdmF0
ZSBPcmdhbml6YXRpb24xEDAOBgNVBAUTBzMwMTQyNjcxCzAJBgNVBAYTAlVTMRMw
EQYDVQQRFAo5NTEzMS0yMDIxMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQH
FAhTYW4gSm9zZTEWMBQGA1UECRQNMjIxMSBOIDFzdCBTdDEVMBMGA1UEChQMUGF5
UGFsLCBJbmMuMRowGAYDVQQLFBFQYXlQYWwgUHJvZHVjdGlvbjEfMB0GA1UEAxQW
d3d3LnNhbmRib3gucGF5cGFsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBAOgLoTxH7wR+fQFXznItNcPuPDKQhdUIWLRvG2uMDQDeolaPF4L5Dvn5
yazgycHMjYBxinH02Sc7k69OqFDCiOiLpIpRLsVCqTZUixIHmsZP6gPMYsYm6a+C
cvpOnqYQ02XE+CIWjN92cK5BKBebtPc9us0MtcPAnuU8Pyp4l7OdLNukjDgXuxZ3
rbnKKb7Z/3kkmzQTeshNWbDLYcgUR2OiibD/lsQpcoYtlPcsXcA+R+HAaYIY3JXc
U2q7RwxCK19kSRcuxKdNNV+/RjBL3Ttbf0LLMiqjWgKpAWpRUjfu08tl7vxR6SCl
aRzoJwnQDwosBtT8I8OiZ8sldmc4btkCAwEAAaOCAfMwggHvMAkGA1UdEwQCMAAw
HQYDVR0OBBYEFE/LQp+SfkYxbltojftEGXrE7GTQMAsGA1UdDwQEAwIFoDBCBgNV
HR8EOzA5MDegNaAzhjFodHRwOi8vRVZTZWN1cmUtY3JsLnZlcmlzaWduLmNvbS9F
VlNlY3VyZTIwMDYuY3JsMEQGA1UdIAQ9MDswOQYLYIZIAYb4RQEHFwYwKjAoBggr
BgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYTAdBgNVHSUEFjAU
BggrBgEFBQcDAQYIKwYBBQUHAwIwHwYDVR0jBBgwFoAU/IpQup65JVp7VYVPlQBj
j+lYa0MwfAYIKwYBBQUHAQEEcDBuMC0GCCsGAQUFBzABhiFodHRwOi8vRVZTZWN1
cmUtb2NzcC52ZXJpc2lnbi5jb20wPQYIKwYBBQUHMAKGMWh0dHA6Ly9FVlNlY3Vy
ZS1haWEudmVyaXNpZ24uY29tL0VWU2VjdXJlMjAwNi5jZXIwbgYIKwYBBQUHAQwE
YjBgoV6gXDBaMFgwVhYJaW1hZ2UvZ2lmMCEwHzAHBgUrDgMCGgQUS2u5KJYGDLvQ
UjibKaxLB4shBRgwJhYkaHR0cDovL2xvZ28udmVyaXNpZ24uY29tL3ZzbG9nbzEu
Z2lmMA0GCSqGSIb3DQEBBQUAA4IBAQAoyJqVjD1/73TyA0GU8Q2hTuTWrUxCE/Cv
D7b3zgR3GXjri0V+V0/+DoczFjn/SKxi6gDWvhH7uylPMiTMPcLDlp8ulgQycxeF
YxgxgcNn37ztw4f2XV/U9N5MRJrrtj5Sr4kAzEk6jPORgh1XfklgPgb1k/mJWWZw
l1AksZwbxMp/adNq1+gyfG65cIgVMiLXYYMr+UJXwey+/e6GVcOhLdEiKmxT6u3M
lsQPBEHGmGM3WDRpCqb7lBPMXP9GkNBfF36IVOu7jzgP69prSKjICk2fPC1+ktAF
KUmGOOMrAuewXyJ8wRuRjbtPikYdApAnHjd7quQWApwUJyOCKr99
-----END CERTIFICATE-----
CERT

chomp(@certificates);

my @cert_contents;
push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/street=2211 N 1st St/O=PayPal, Inc./OU=PayPal Production/CN=www.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/street=2211 N 1st St/O=PayPal, Inc./OU=Hosting Support/CN=www.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/2.5.4.15=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/streetAddress=2211 N 1st St/O=PayPal, Inc./OU=PayPal Production/CN=www.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/2.5.4.15=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/streetAddress=2211 N 1st St/O=PayPal, Inc./OU=Hosting Support/CN=www.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/2.5.4.15=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/streetAddress=2211 N 1st St/O=PayPal, Inc./OU=PayPal Production/CN=www.sandbox.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

chomp(@cert_contents);

sub new {
	my $class = shift;

	my $self = {
		address => 'https://www.paypal.com/cgi-bin/webscr',
		@_,
	};
	bless $self, $class;
	$self->{id} = md5_hex(rand()) unless $self->{id};
	$self->{address} = 'https://www.sandbox.paypal.com/cgi-bin/webscr' if $self->{sandbox};

	return $self;
}

#creates a PayPal button
sub button {
	my $self = shift;

	my %buttonparam = (
		cmd                 => '_ext-enter',
		redirect_cmd        => '_xclick',
		button_image        => qq{<input type="image" name="submit" src="http://images.paypal.com/images/x-click-but01.gif" alt="Make payments with PayPal" />},
		business            => undef,
		item_name           => undef,
		item_number         => undef,
		image_url           => undef,
		no_shipping         => 1,
		return              => undef,
		cancel_return       => undef,
		no_note             => 1,
		undefined_quantity  => 0,
		notify_url          => undef,
		first_name          => undef,
		last_name           => undef,
		shipping            => undef,
		shipping2           => undef,
		quantity            => undef,
		amount              => undef,
		address1            => undef,
		address2            => undef,
		city                => undef,
		state               => undef,
		zip                 => undef,
		night_phone_a       => undef,
		night_phone_b       => undef,
		night_phone_c       => undef,
		day_phone_a         => undef,
		day_phone_b         => undef,
		day_phone_c         => undef,
		receiver_email      => undef,
		invoice             => undef,
		currency_code       => undef,
		custom              => undef,
		@_,
	);
	my $key;
	my $content = qq{<form method="post" action="$self->{address}" enctype="multipart/form-data">};

	foreach my $param (sort keys %buttonparam) {
		next if not defined $buttonparam{$param};
		next if $param eq 'button_image';
		$content .= qq{<input type="hidden" name="$param" value="$buttonparam{$param}" />};
	}
	$content .= $buttonparam{button_image};
	$content .= qq{</form>};

	return $content;
}


# takes a reference to a hash of name value pairs, such as from a CGI query
# object, which should contain all the name value pairs which have been
# posted to the script by PayPal's Instant Payment Notification
# posts that data back to PayPal, checking if the ssl certificate matches,
# and returns success or failure, and the reason.
sub pdtvalidate {
	my $self = shift;

	my $query =
	{
		cmd => '_notify-synch',
		@_,
	};

	my $address = $self->{address};
	my ($site, $port, $path);

	#following code splits an url into site, port and path components
	my @address = split /:\/\//, $address, 2;
	@address = split /(?=\/)/, $address[1], 2;
	if ($address[0] =~ /:/) {
		($site, $port) = split /:/, $address[0];
	}
	else {
		($site, $port) = ($address[0], '443');
	}
	$path = $address[1];
	my ($page,
		$response,
		$headers,
		$ppcert,
		) = Net::SSLeay::post_https3($site,
										$port,
										$path,
										'',
										Net::SSLeay::make_form(%$query));


	my $ppx509 = Net::SSLeay::PEM_get_string_X509($ppcert);
	my $ppcertcontent =
	'Subject Name: '
		. Net::SSLeay::X509_NAME_oneline(
			Net::SSLeay::X509_get_subject_name($ppcert))
			. "\nIssuer  Name: "
				. Net::SSLeay::X509_NAME_oneline(
					Net::SSLeay::X509_get_issuer_name($ppcert))
					. "\n";

	chomp $ppx509;
	chomp $ppcertcontent;

	# TODO warn if there is a value in $Cert or $Certcontent as those will be deprecated
	my @certs = @certificates;
	if ($Cert) {
		# TODO warn
		push @certs, $Cert;
	}
	my @cert_cont = @cert_contents;
	if ($Certcontent) {
		# TODO warn
		push @cert_cont, $Certcontent;
	}

# 	die "PayPal cert failed to match: $ppx509" unless grep {$_ eq $ppx509} @certs;
# 	die "PayPal cert contents failed to match $ppcertcontent" unless grep { $_ eq $ppcertcontent } @cert_cont;
	return undef if $page =~ /^FAIL\n/s;
	return { map { /^([^=]+)(?:=(.*))?$/ } split("\n", $page) } if $page =~ /^SUCCESS\n/s;
	die "Bad stuff happened\n$page";
}

1;
