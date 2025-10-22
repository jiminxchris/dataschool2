from flask import Flask, render_template,request, redirect, url_for, flash
import psycopg2
from psycopg2.extras import DictCursor
import os
import db
from datetime import datetime
import seaborn as sns
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm

app = Flask(__name__)
app.secret_key = os.urandom(24)
my_password = db.my_password

plt.rc('font', family='Malgun Gothic', size=11)
plt.rc('axes', unicode_minus = False)

def get_db_connection():
    conn = psycopg2.connect(
    host = 'localhost', 
    port = 5432, 
    dbname='my_postgres', 
    user = 'postgres', 
    password=my_password)
    print('get_db_connection', conn)
    conn.autocommit = True
    return conn

@app.route('/')
def index():
    # 1. 데이터 베이스에 접속
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=DictCursor)
    # 2. SELECT
    cursor.execute("SELECT id, title, author, created_at, view_count, like_count FROM board.posts ORDER BY created_at DESC")
    posts = cursor.fetchall()
    cursor.close()
    conn.close()
    # 3. index.html 파일에 변수로 넘겨주기
    return render_template('index.html', posts = posts)

@app.route('/fms/')
def fms():
    # 1. 데이터 베이스에 접속
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=DictCursor)
    # 2. SELECT
    cursor.execute("SELECT * FROM fms.total_result")
    results = cursor.fetchall()

    cursor.close()
    conn.close()
    # 3. index.html 파일에 변수로 넘겨주기
    return render_template('fms.html',results = results )

@app.route('/dashboard/')
def dashboard():
    # 1. 데이터 베이스에 접속
    conn = get_db_connection()

    # 2. SELECT
    chick_info = pd.read_sql_query("SELECT * FROM fms.chick_info",conn)
    prod_result = pd.read_sql_query("SELECT * FROM fms.prod_result",conn)

    conn.close()

    chick_prod = pd.merge(chick_info, prod_result, on='chick_no', how='inner')
    plt.figure(figsize=(10, 6))
    sns.boxplot(x='breeds', y='raw_weight', data=chick_prod)
    plt.title('품종별 최종 무게 분포')
    plt.xlabel('품종')
    plt.ylabel('최종 무게 (g)')

    plt.tight_layout()
    image_file = 'breeds_weight_distribution.png'
    plt.savefig(f'static/{image_file}')
    # 3. index.html 파일에 변수로 넘겨주기
    return render_template('dashboard.html',image_file = image_file )

@app.route('/create/', methods=['GET'] )
def create_form():
    return render_template('create.html')

@app.route('/create/',methods=['POST']  )
def create_post():
    #1. 폼에 있는 정보들을 get
    title = request.form.get('title')
    author = request.form.get('author')
    content = request.form.get('content')

    if not title or not author or not content:
        flash('모든 필드를 똑바로 채워주세요!!!!')
        return redirect(url_for('create_form'))
    
    # 1. 데이터 베이스에 접속
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=DictCursor)
    # 2. INSERT
    cursor.execute("INSERT INTO board.posts (title, content, author) VALUES (%s, %s, %s) RETURNING id", (title,author,content ))
    post_id = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    flash('게시글이 성공적으로 등록되었음')
    return redirect(url_for('view_post', post_id=post_id))

@app.route('/post/<int:post_id>')
def view_post(post_id):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=DictCursor)
    
    cursor.execute('UPDATE board.posts SET view_count = view_count + 1 WHERE id = %s', (post_id,))
    
    cursor.execute('SELECT * FROM board.posts WHERE id = %s', (post_id,))
    post = cursor.fetchone()
    
    if post is None:
        cursor.close()
        conn.close()
        flash('게시글을 찾을 수 없습니다.')
        return redirect(url_for('index'))
    
    cursor.execute('SELECT * FROM board.comments WHERE post_id = %s ORDER BY created_at', (post_id,))
    comments = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    user_ip = request.remote_addr
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM board.likes WHERE post_id = %s AND user_ip = %s', (post_id, user_ip))
    liked = cursor.fetchone()[0] > 0
    cursor.close()
    conn.close()
    
    return render_template('view.html', post=post, comments=comments, liked=liked)

@app.route('/edit/<int:post_id>', methods=['GET'])
def edit_form(post_id):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=DictCursor)
    cursor.execute('SELECT * FROM board.posts WHERE id = %s', (post_id,))
    post = cursor.fetchone()
    cursor.close()
    conn.close()
    
    if post is None:
        flash('게시글을 찾을 수 없습니다.')
        return redirect(url_for('index'))
    
    return render_template('edit.html', post=post)

@app.route('/edit/<int:post_id>', methods=['POST'])
def edit_post(post_id):
    title = request.form.get('title')
    content = request.form.get('content')
    
    if not title or not content:
        flash('제목과 내용을 모두 입력해주세요.')
        return redirect(url_for('edit_form', post_id=post_id))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        'UPDATE board.posts SET title = %s, content = %s, updated_at = %s WHERE id = %s',
        (title, content, datetime.now(), post_id)
    )
    cursor.close()
    conn.close()
    
    flash('게시글이 성공적으로 수정되었습니다.')
    return redirect(url_for('view_post', post_id=post_id))

@app.route('/delete/<int:post_id>', methods=['POST'])
def delete_post(post_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM board.posts WHERE id = %s', (post_id,))
    cursor.close()
    conn.close()
    
    flash('게시글이 성공적으로 삭제되었습니다.')
    return redirect(url_for('index'))

@app.route('/post/comment/<int:post_id>', methods=['POST'])
def add_comment(post_id):
    author = request.form.get('author')
    content = request.form.get('content')
    
    if not author or not content:
        flash('작성자와 내용을 모두 입력해주세요.')
        return redirect(url_for('view_post', post_id=post_id))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO board.comments (post_id, author, content) VALUES (%s, %s, %s)',
        (post_id, author, content)
    )
    cursor.close()
    conn.close()
    
    flash('댓글이 등록되었습니다.')
    return redirect(url_for('view_post', post_id=post_id))

@app.route('/post/like/<int:post_id>', methods=['POST'])
def like_post(post_id):
    user_ip = request.remote_addr
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM board.likes WHERE post_id = %s AND user_ip = %s', (post_id, user_ip))
    already_liked = cursor.fetchone()[0] > 0
    
    if already_liked:
        cursor.execute('DELETE FROM board.likes WHERE post_id = %s AND user_ip = %s', (post_id, user_ip))
        cursor.execute('UPDATE board.posts SET like_count = like_count - 1 WHERE id = %s', (post_id,))
        message = '좋아요가 취소되었습니다.'
    else:
        cursor.execute('INSERT INTO board.likes (post_id, user_ip) VALUES (%s, %s)', (post_id, user_ip))
        cursor.execute('UPDATE board.posts SET like_count = like_count + 1 WHERE id = %s', (post_id,))
        message = '좋아요가 등록되었습니다.'
    
    cursor.close()
    conn.close()   
    flash(message)
    return redirect(url_for('view_post', post_id=post_id))

if __name__ == '__main__':
    print('main start')
    app.run(debug=True)