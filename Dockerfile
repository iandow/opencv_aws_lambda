FROM amazonlinux

RUN yum update -y
RUN yum install gcc openssl-devel bzip2-devel libffi-devel wget tar gzip zip make zlib-devel libglvnd-glx mesa-libGL -y

# Install Python 3.11
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz
RUN tar -xzvf Python-3.11.5.tgz
WORKDIR /Python-3.11.5
RUN ./configure --enable-optimizations
RUN make altinstall


# Install Python packages
RUN mkdir /packages
RUN echo "opencv-python" >> /packages/requirements.txt
RUN mkdir -p /packages/opencv-python-3.11/python/lib/python3.11/site-packages
RUN pip3.11 install -r /packages/requirements.txt -t /packages/opencv-python-3.11/python/lib/python3.11/site-packages

# Create zip files for Lambda Layer deployment
WORKDIR /packages/opencv-python-3.11/
RUN zip -r9 /packages/cv2-python311.zip .
WORKDIR /packages/
RUN rm -rf /packages/opencv-python-3.11/
