FROM amazonlinux

RUN yum update -y
RUN yum install gcc openssl-devel bzip2-devel libffi-devel wget tar gzip zip make -y

# Install Python 3.9
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.9.10/Python-3.9.10.tgz
RUN tar -xzvf Python-3.9.10.tgz
WORKDIR /Python-3.9.10
RUN ./configure --enable-optimizations
RUN make altinstall

# Install Python 3.8
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz
RUN tar -xzvf Python-3.8.12.tgz
WORKDIR /Python-3.8.12
RUN ./configure --enable-optimizations
RUN make altinstall

# Install Python 3.7
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tgz
RUN tar -xzvf Python-3.7.12.tgz
WORKDIR /Python-3.7.12
RUN ./configure --enable-optimizations
RUN make altinstall

# Install Python packages
RUN mkdir /packages
RUN echo "opencv-python" >> /packages/requirements.txt
RUN mkdir -p /packages/opencv-python-3.7/python/lib/python3.7/site-packages
RUN mkdir -p /packages/opencv-python-3.8/python/lib/python3.8/site-packages
RUN mkdir -p /packages/opencv-python-3.8/python/lib/python3.9/site-packages
RUN pip3.7 install -r /packages/requirements.txt -t /packages/opencv-python-3.7/python/lib/python3.7/site-packages
RUN pip3.8 install -r /packages/requirements.txt -t /packages/opencv-python-3.8/python/lib/python3.8/site-packages
RUN pip3.9 install -r /packages/requirements.txt -t /packages/opencv-python-3.9/python/lib/python3.9/site-packages

# Create zip files for Lambda Layer deployment
WORKDIR /packages/opencv-python-3.7/
RUN zip -r9 /packages/cv2-python37.zip .
WORKDIR /packages/opencv-python-3.8/
RUN zip -r9 /packages/cv2-python38.zip .
WORKDIR /packages/opencv-python-3.9/
RUN zip -r9 /packages/cv2-python39.zip .
WORKDIR /packages/
RUN rm -rf /packages/opencv-python-3.7/
RUN rm -rf /packages/opencv-python-3.8/
RUN rm -rf /packages/opencv-python-3.9/
