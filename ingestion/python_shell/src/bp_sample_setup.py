from setuptools import setup

setup(
    name="bp_sample",
    version="0.1",
    include_package_data=True,
    packages=["config"],
    package_dir={
                'config':'../../../utility/src/config',
                 },
    install_requires=['XlsxWriter==1.2.2', 's3fs==0.3.5'],
    package_data ={'config':['env.py']}
)