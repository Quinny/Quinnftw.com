bundle exec jekyll build
gsutil rsync -R _site "gs://quinnftw.com"
gsutil acl ch -r -u AllUsers:R "gs://quinnftw.com"
gsutil web set -m index.html "gs://quinnftw.com"
