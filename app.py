import yaml
from flask import Flask, request, redirect, url_for, render_template
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from mernis import verify_identity
from log_handler import log_event, sign_log_file
from password_generator import generate_password

# Config dosyasını yükleme
with open('/usr/local/captive-portal/config.yaml', 'r') as config_file:
    config = yaml.safe_load(config_file)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
app.config['SQLALCHEMY_DATABASE_URI'] = config['database']['uri']
db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = 'admin_login'

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

@app.before_first_request
def create_admin():
    admin_user = User.query.filter_by(username=config['admin']['username']).first()
    if not admin_user:
        admin = User(username=config['admin']['username'], password=config['admin']['password'])
        db.session.add(admin)
        db.session.commit()

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['POST'])
def login():
    tc_kimlik_no = request.form['tc_kimlik_no']
    ad = request.form['ad']
    soyad = request.form['soyad']
    dogum_yili = request.form['dogum_yili']
    
    if verify_identity(tc_kimlik_no, ad, soyad, dogum_yili):
        password = generate_password()
        log_event(f"User with T.C. Kimlik No {tc_kimlik_no} authenticated successfully. Assigned password: {password}")
        return render_template('success.html', password=password)
    else:
        log_event(f"User with T.C. Kimlik No {tc_kimlik_no} failed MERNIS authentication.")
        return redirect(url_for('index', error="MERNIS Authentication Failed"))

@app.route('/admin')
@login_required
def admin():
    return render_template('admin.html')

@app.route('/users')
@login_required
def users():
    users = User.query.all()
    return render_template('users.html', users=users)

@app.route('/settings')
@login_required
def settings():
    return render_template('settings.html')

@app.route('/sign_logs')
@login_required
def sign_logs():
    sign_log_file(config['private_key_path'], config['log_file_path'], config['signature_path'])
    return "Logs signed successfully."

@app.route('/admin_login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = User.query.filter_by(username=username).first()
        if user and user.password == password:
            login_user(user)
            return redirect(url_for('admin'))
    return render_template('admin_login.html')

@app.route('/admin_logout')
@login_required
def admin_logout():
    logout_user()
    return redirect(url_for('admin_login'))

if __name__ == '__main__':
    db.create_all()
    app.run(host='0.0.0.0', port=config['captive_portal']['port'])
