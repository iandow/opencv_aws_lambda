FROM amazonlinux:2

RUN yum install wget tar gzip zip make openssl11 openssl11-devel libffi-devel bzip2-devel mesa-libGL -y

# Install Python 3.11
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz
RUN tar -xzvf Python-3.11.5.tgz
WORKDIR /Python-3.11.5
RUN ./configure --prefix=/usr --enable-optimizations
RUN make -j $(nproc)
RUN make altinstall

# Install Python packages
RUN mkdir /packages
RUN mkdir -p /packages/opencv-python-3.11/python/lib/python3.11/site-packages
RUN pip3.11 install opencv-python-headless -t /packages/opencv-python-3.11/python/lib/python3.11/site-packages

# Create zip files for Lambda Layer deployment
WORKDIR /packages/opencv-python-3.11/
RUN zip -r9 /packages/cv2-python311.zip .
WORKDIR /packages/
RUN rm -rf /packages/opencv-python-3.11/
