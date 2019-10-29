class Env():
    @staticmethod
    def get_config(project, stage):
        if stage == 'prod':
            return Env.get_prod_config(project)

        if stage == 'qa':
            return Env.get_qa_config(project)

        return Env.get_dev_config(project)

    @staticmethod
    def get_prod_config(project):
        STAGE = 'prod'
        return {
            'aws_region':'us_west_1',
            's3_data_lake':'{}-data-lake-{}'.format(project, STAGE),
            'incoming_folder':'incoming',
            'primary_folder': 'primary',
            'glue_role':'{}_glue_role_{}'.format(project, STAGE)
        }
    
    @staticmethod
    def get_qa_config(project):
        STAGE = 'qa'
        return {
            'aws_region':'us_east_2',
            's3_data_lake':'{}-data-lake-{}'.format(project, STAGE),
            'incoming_folder':'incoming',
            'primary_folder': 'primary',
            'glue_role':'{}_glue_role_{}'.format(project, STAGE)
        }
    
    @staticmethod
    def get_dev_config(project):
        STAGE = 'dev'
        return {
            'aws_region':'us_east_1',
            's3_data_lake':'{}-data-lake-{}'.format(project, STAGE),
            'incoming_folder':'incoming',
            'primary_folder': 'primary',
            'glue_role':'{}_glue_role_{}'.format(project, STAGE)
        }