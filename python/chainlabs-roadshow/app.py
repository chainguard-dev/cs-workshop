from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)

# In-memory vote counts
vote_counts = {
    'Dogs': 0,
    'Cats': 0
}

@app.route('/')
def index():
    # Prepare results for template
    formatted_results = [
        ('Dogs', vote_counts.get('Dogs', 0)),
        ('Cats', vote_counts.get('Cats', 0))
    ]
    return render_template('index.html', results=formatted_results)

@app.route('/vote', methods=['POST'])
def vote():
    option = request.form['option']
    if option in vote_counts:
        vote_counts[option] += 1
    return redirect(url_for('index'))

if __name__ == '__main__':
    print("Starting voting app (no database)...")
    app.run(host='0.0.0.0', port=5000, debug=True)