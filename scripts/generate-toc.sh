#!/bin/sh

# A script to run in the hugo/content/references directory to make a ToC of the API calls
# Depends on Magic Pipes being installed (install Chicken Scheme, then "chicken-install magic-pipes")

egrep "^(#### DotmeshRPC|### )" api.md | sed 's/.$//' | (
	 while read;
	 do
		  case "$REPLY" in
				\#\#\#\ *)
					 echo "$REPLY" | sed 's/^### / * /'
					 ;;
				*)
					 echo "$REPLY" | mpre '(seq "#### " (=> ref (* any)))' | mpforeach "(lambda (m) (let ((ref (alist-ref m 'ref))) (printf \"   * [~a](#~a)\n\" ref (irregex-replace \"[^a-z]\" (string-downcase ref) \"-\"))))"
					 ;;
		  esac
	 done
	 )
