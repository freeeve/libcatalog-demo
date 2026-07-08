module github.com/freeeve/libcat-demo

go 1.25

require github.com/freeeve/libcat/hugo v0.0.0

// Local dev resolves the Hugo module from the sibling working tree. CI/deploy pins a
// published module version instead (see tasks/003_s3-cloudfront-deploy.md).
replace github.com/freeeve/libcat/hugo => ../libcat/hugo
