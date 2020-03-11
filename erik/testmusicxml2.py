from music21 import *
import webbrowser, os, random, pathlib

osmd_js_file = os.path.join(os.path.dirname(os.path.realpath(__file__)),"opensheetmusicdisplay.min.js.txt")

if not pathlib.Path(osmd_js_file).is_file():
    print("ERROR: need ./opensheetmusicdisplay.min.js.txt at",osmd_js_file) 
    exit()
print("found required .js")


selected_piece = random.choice(corpus.getPaths())
print('loading piece', selected_piece)
b = corpus.parse(selected_piece)
b = converter.parse("Vem_kan_segla.musicxml")


def stream_to_web(b):
    html_template = """
    <html>
        <head>
            <meta http-equiv="content-type" content="text/html; charset=utf-8" />
            <title>Music21 Fragment</title>
            <script src="{osmd_js_path}"></script>
        </head>
        <body>
            <div id='main-div'></div>
            <button opensheetmusicdisplayClick="show_xml()">Show xml</button>
            <pre id='xml-div'></pre>
            <script>
            var data = `{data}`;
            function show_xml() {{
                document.getElementById('xml-div').textContent = data;
            }}

              var openSheetMusicDisplay = new opensheetmusicdisplay.OpenSheetMusicDisplay("main-div");
              openSheetMusicDisplay
                .load(data)
                .then(
                  function() {{
                    console.log(openSheetMusicDisplay.render());
                  }}
                );
            </script>
        </body>

    """

    osmd_js_path = pathlib.Path(osmd_js_file).as_uri()

    filename = b.write('musicxml')
    print("musicXML filename:",filename)
    if filename is not None:
        with open(filename,'r') as f:
            xmldata = f.read()
        with open(filename+'.html','w') as f_html:
            html = html_template.format(
                data=xmldata.replace('`','\\`'),
                osmd_js_path=osmd_js_path)
            f_html.write(html)

        webbrowser.open('file://' + os.path.realpath(filename+'.html'))


stream_to_web(b)