This project is a simple conversion function that takes as input an SCXML file and produces as output (stdout actually) the correspondent finite state machine network using the DOT language.

For a guide on the DOT language see: http://www.graphviz.org/Documentation.php

For a guide on SCXML see: http://www.w3.org/TR/scxml/
or: http://commons.apache.org/scxml/guide/scxml-documents.html
or: http://en.wikipedia.org/wiki/SCXML

Usage: ./scxml2dot.pl file.scxml |dot -Tpdf > file.pdf

the perl script is here: http://code.google.com/p/scxml2dot/source/browse/trunk/scxml2dot.pl

A full editor is available at: http://code.google.com/p/scxmlgui/