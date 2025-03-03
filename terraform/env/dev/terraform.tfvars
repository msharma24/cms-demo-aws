environment           = "dev"
aws_region            = "us-east-1"
vpc_cidr_range        = "172.17.0.0/20"
private_subnets_list  = ["172.17.0.0/24", "172.17.1.0/24"]
public_subnets_list   = ["172.17.3.0/24", "172.17.4.0/24"]
database_subnets_list = ["172.17.6.0/24", "172.17.7.0/24"]

public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD0YgrVVIcvqxp34XSZPTBRYas6MGIlcCyZVzs/BmXpxl/3N+KB33VEfWguTWcXwhQun/J8/hjiEOqrknem91D9qfO/PfrLV/zeE05zKJEgmgJPjJaf2TYRFUZzTZyNmj2p2uPe7/12XhP5JqF7F4lk65eP1hdqLw51JauIxyt3yUS6DaHqSzdbWbrOqkQvpQrY2s/6CnDbLHLzRpnNnbJ5ORkM50obCuoy84C/JvAbrZm3sHTu+TXAvxcTXO5tCPK3i7peUdlnGHKN1Na+jln9xkMscgeSwHM1l/Oh0/YpM/88MMgRQvvYhd/944WRgH/WYknsQQDm83t14jUYhR7JNe0HeuaW9pHFCGLuuOshrKEaV9SPb/2324mnkTzwMGzlVLYTGLqM55NWc57x5BQK1obESM9RlGZA1bPkX5HRg/9Vraes+D8BB7CYiDrdIJlR+Q3t551vgyI9ygiIZmvtHdNQJk6Ww5XY3GbQZmaOjq1oyFZPhq1xB2gvMUVONnM= mukesh.sharma@Mukesh-Sharmas-Macbook-Pro.local"

ssm_params_list = [
  "DB_USER",
  "DB_HOST",
  "PARTNERS_EXAMPLE_PUBLIC_KEY",
  "EXAMPLE_PARTNER_RSA_KEY", # Remove this key in production
  "PROVIDERS_STETSON_INITIAL_TEST_KEY",
  "PROVIDERS_STETSON_INITIAL_TEST_LOGIN_NAME",
  "PROVIDERS_STETSON_INITIAL_TEST_LOGIN_PASSWORD",
  "PROVIDERS_CAPITAL_INITIAL_TEST_KEY",
  "PROVIDERS_CAPITAL_INITIAL_TEST_SITE_ID",
  "PROVIDERS_CAPITAL_INITIAL_TEST_LOGIN_NAME",
  "PROVIDERS_AGILE_INITIAL_TEST_KEY",
  "PROVIDERS_AGILE_INITIAL_TEST_LOGIN_NAME",
  "PROVIDERS_CAPITAL_INITIAL_TEST_LOGIN_PASSWORD__SKIP",
  "PROVIDERS_AGILE_INITIAL_TEST_LOGIN_PASSWORD__SKIP",
  "PROVIDERS_AGILE_INITIAL_TEST_USER_ID__SKIP",
  "UTILITIES_SIGNNOW_CLIENT_ID",
  "UTILITIES_SIGNNOW_CLIENT_SECRET",
  "UTILITIES_SIGNNOW_ENVIRONMENT",
  "UTILITIES_SIGNNOW_USERNAME",
  "UTILITIES_SIGNNOW_PASSWORD",
  "SNYK_TOKEN",
  "SQS_QUEUE_NAME"
]

github_connection_arn          = "arn:aws:codestar-connections:us-east-1:318108814388:connection/70118b12-83c2-44f7-827c-067fbb6e5d2a"
phoenix_api_gw_route53_zone_id = "Z03596132MDRSNY6NT2Q3"
#"Z06806031YUXHTLW0L70X"
phoenix_api_gw_route53_custom_dns_record = "dev.api.pavoinsurance.com"

create_aurora_serverless = false

hw_api_gw_route53_zone_id           = "Z06806031YUXHTLW0L70X"
hw_api_gw_route53_custom_dns_record = "demo.grus-api.com"

partners_example_public_key = "-----BEGIN PUBLIC KEY----- MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA24hi+YJXPt3yEUCVwMe4 DgLhUKVII4mKzQytD+Wnavu/rEsq0VXuc6DkUwUFrHBeO+sSL3A+23NYVOnDYyIP We858z1iE+ZK2PusbFYumAfvLTs/bYS33NE8k6AV7zrBFEIvFgDwD6VpXo4tWfsN /aGOSL4rmNucWYWku5qzGkbDx1IC8Hteu8QpEnMuiXOi3qyAmDYztf581NHBBP16 AA1zds2RB3Ro2xfXsrs+VeLq53I30PQhkNW7PNuZ7m8Lt77ASdtWjSQW5EQZZ5iu a4eiEU/1/97mSkjAE8WGWhDEymglC2izx00AU7qnLrrHBmKz4K1dqkaghIzdIeQL ZBSjCDVix8/t3pD03Y51gtDJsJ6XW+jDdsqV0q6wsyDHdYDjZ4HgGm8qpaKfiGbr FxBC7z04oo65hyo2iqUG1Y/oGehVetlBaq0IqJTy+MvZiF3GXNE+am8z14E99Rin c32lfnf53O1rgVQftIZXK/jNK40SNQPdX7P5gDOY+JUljTfcPSZkPVKF4XRDY6cZ ZjLxtE1F8Jg10qG4ptcVvKwHjHTb8G1CHUli9pgsnmE0FO2ojS8XrkAzmENyzrHx lE4FWH9+Zo+zw5DCOX5hdJUS1P0Vl0oqR5d/3Ipt7s7HuRKyJEFtKDtSXXFD7Sij CPvSnhokd0AkrYGkgNmlTx0CAwEAAQ== -----END PUBLIC KEY-----"

create_api_pavoinsurance_zone   = true
create_demo_api_pavoinsure_zone = false
grus_repo_branch_name           = "main"
