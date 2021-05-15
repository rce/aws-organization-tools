# AWS organization tools

Bunch of scripts to make spinning up new AWS accounts easier.

I try to use single AWS account per project and environment. This allows me to
easily nuke projects when they have outlived their usefulness.

## create-account.sh

```
rce@DESKTOP-II7DD6B:~/dev/aws-organization-tools$ ./create-account.sh pokemon-go-calendar
{
    "UserId": "AIDA372CDMXIU24ALPLMO",
    "Account": "824235484625",
    "Arn": "arn:aws:iam::824235484625:user/rce@rce.fi"
}
2021-05-16 21:38:40 INFO Creating account pokemon-go-calendar
2021-05-16 21:38:42 INFO Waiting for account to be created
2021-05-16 21:38:43 INFO Still waiting for account to be created...
2021-05-16 21:38:50 INFO Account has been created
2021-05-16 21:38:51 INFO Generating aws_config in /home/rce/dev/aws-organization-tools/configs/pokemon-go-calendar
2021-05-16 21:38:51 INFO Testing generated aws configuration
~/dev/aws-organization-tools/configs ~/dev/aws-organization-tools
{
    "UserId": "AROA4KDCCWJDD7PRWTRQU:botocore-session-1621190332",
    "Account": "846314254918",
    "Arn": "arn:aws:sts::846314254918:assumed-role/OrganizationAccountAccessRole/botocore-session-1621190332"
}
~/dev/aws-organization-tools
2021-05-16 21:38:54 INFO Account created and tested successfully
rce@DESKTOP-II7DD6B:~/dev/aws-organization-tools$ cat configs/pokemon-go-calendar
[profile pokemon-go-calendar]
source_profile = rce-organization
role_arn = arn:aws:iam::846314254918:role/OrganizationAccountAccessRole
rce@DESKTOP-II7DD6B:~/dev/aws-organization-tools$
```
