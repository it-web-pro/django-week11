-- Insert Departments
INSERT INTO company_department (name, manager_id) VALUES
('IT', 1),
('HR', 2),
('Finance', 3),
('Marketing', 4),
('Operations', 5);


-- Insert Positions
INSERT INTO company_position (name, description, department_id) VALUES
('Software Developer', 'Develops software applications.', 1),
('System Administrator', 'Maintains IT infrastructure.', 1),
('Network Engineer', 'Designs and manages computer networks.', 1),
('HR Manager', 'Oversees HR department.', 2),
('Recruiter', 'Recruits new employees.', 2),
('Payroll Specialist', 'Manages payroll.', 2),
('Accountant', 'Handles financial records.', 3),
('Financial Analyst', 'Analyzes financial data.', 3),
('Auditor', 'Conducts financial audits.', 3),
('Marketing Manager', 'Oversees marketing department.', 4),
('Content Creator', 'Creates marketing content.', 4),
('SEO Specialist', 'Optimizes search engine visibility.', 4),
('Operations Manager', 'Oversees operations department.', 5),
('Logistics Coordinator', 'Manages logistics.', 5),
('Warehouse Manager', 'Manages warehouse operations.', 5),
('Data Scientist', 'Analyzes data and provides insights.', 1),
('Product Manager', 'Oversees product development.', 4),
('Customer Support', 'Provides customer support.', 5),
('Sales Manager', 'Manages sales team.', 4),
('Quality Assurance', 'Ensures product quality.', 1);