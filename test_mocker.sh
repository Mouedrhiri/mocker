#!/usr/bin/env bash
set -euo pipefail

M='bash /usr/local/bin/mocker'

echo "============================================"
echo "  mocker - Made by Mohammed Ouedrhiri"
echo "============================================"

echo ""
echo "=== mocker images ==="
$M images

echo ""
echo "=== mocker ps ==="
$M ps

echo ""
echo "=== mocker run: uname ==="
$M run img_alpine_latest uname -a

echo ""
echo "=== mocker run: hostname ==="
$M run img_alpine_latest hostname

echo ""
echo "=== mocker run: /etc/alpine-release ==="
$M run img_alpine_latest cat /etc/alpine-release

echo ""
echo "=== mocker run: id ==="
$M run img_alpine_latest id

echo ""
echo "=== mocker run: ls / ==="
$M run img_alpine_latest ls /

echo ""
echo "=== mocker ps (after runs) ==="
$M ps

echo ""
echo "=== mocker inspect last container ==="
LAST=$($M ps | awk 'NR>1 && NF{last=$1} END{print last}')
$M inspect "$LAST"

echo ""
echo "=== mocker logs last container ==="
$M logs "$LAST"

echo ""
echo "=== mocker tag img_alpine_latest img_alpine_test ==="
$M tag img_alpine_latest img_alpine_test

echo ""
echo "=== mocker images (after tag) ==="
$M images

echo ""
echo "=== ALL TESTS PASSED ==="
