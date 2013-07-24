AWSbooklist
===========

This project contains a [MS PowerShell](http://www.microsoft.com/powershell) script
for gathering information about a list of books by their ISBN from 
[amazon](http://www.amazon.com/books) and creating a HTML fragment for a book list.

It is using the [Amazon Product Advertising API](http://docs.aws.amazon.com/AWSECommerceService/2011-08-01/GSG/Welcome.html)
to obtain the required information.

Preconditions
-------------

To use the API you must have a [AWS](http://aws.amazon.com/) account with your
_AWS Access Key_ and the corresponding _AWS Private Key_. Additionally to
use the product advertising API you need to register your AWS account at the
[Amazon Affiliate Program](https://affiliate-program.amazon.com/) to get
an [_Associate ID_](http://docs.aws.amazon.com/AWSECommerceService/2011-08-01/GSG/GettingSetUp.html).

These three tokens need to be present in the `aws.config.ps1`. You can find
a template for the config file in `aws.config.ps1.template`. Just rename it
and fill in your credentials.

Usage
-----

Setup a list with ISBN codes of books you want to list. Write these codes into
a plain text file, one code per line.

Call `Create-BookList.ps1 my-book-list.txt` 
and the result is saved into `my-book-list.html`  

* You can specify the target file to: 
  `Create-BookList.ps1 my-book-list.txt result.htm`
* You can omit the included default CSS styles: 
  `Create-BookList.ps1 my-book-list.txt -noStyles`
* You can embed the result fragment in a simple HTML page:
  `Create-BookList.ps1 my-book-list.txt -noFragment`
