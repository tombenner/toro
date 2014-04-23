def job_should_have_attributes(job, attributes)
  attributes.stringify_keys!
  job.attributes.should include(attributes)
end
