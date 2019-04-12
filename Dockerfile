FROM amazonlinux

WORKDIR /packages
RUN yum update -y

# Install Python 3.7
RUN yum install python3 zip -y
RUN mkdir -p /packages/opencv-python-3.7/python/lib/python3.7/site-packages

# Install Python 3.6
RUN yum groupinstall -y development
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm
RUN yum install -y python36u
RUN yum install -y python36u-pip
RUN mkdir -p /packages/opencv-python-3.6/python/lib/python3.6/site-packages

# Install Python packages
RUN echo "opencv-python=4.1.0.25" >> /packages/requirements.txt
RUN pip3.7 install -r /packages/requirements.txt -t /packages/opencv-python-3.7/python/lib/python3.7/site-packages
RUN pip3.6 install -r /packages/requirements.txt -t /packages/opencv-python-3.6/python/lib/python3.6/site-packages

# Create zip files for Lambda Layer deployment
WORKDIR /packages/opencv-python-3.7/
RUN zip -r9 /packages/cv2-python37.zip .
WORKDIR /packages/opencv-python-3.6/
RUN zip -r9 /packages/cv2-python36.zip .
WORKDIR /packages/
RUN rm -rf /packages/opencv-python-3.7/
RUN rm -rf /packages/opencv-python-3.6/