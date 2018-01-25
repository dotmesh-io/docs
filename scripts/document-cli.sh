#!/bin/sh

echo "### \`$@\`."
echo ""
echo '<div class="highlight"><pre class="chromaManual">'
echo "\$ <kbd>$@</kbd>"
"$@"
echo '</pre></div>'
