import { createClient } from '@supabase/supabase-js'

let Uploaders = {}

// https://hexdocs.pm/phoenix_live_view/uploads-external.html#direct-to-s3
// Uploaders.S3 = function(entries, onViewError){
//   entries.forEach(entry => {
//     let formData = new FormData()
//     let {url, fields} = entry.meta
//     Object.entries(fields).forEach(([key, val]) => formData.append(key, val))
//     formData.append("file", entry.file)
//     let xhr = new XMLHttpRequest()
//     onViewError(() => xhr.abort())
//     xhr.onload = () => xhr.status === 204 ? entry.progress(100) : entry.error()
//     xhr.onerror = () => entry.error()
//     xhr.upload.addEventListener("progress", (event) => {
//       if(event.lengthComputable){
//         let percent = Math.round((event.loaded / event.total) * 100)
//         if(percent < 100){ entry.progress(percent) }
//       }
//     })

//     xhr.open("POST", url, true)
//     xhr.send(formData)
//   })
// }

Uploaders.Supabase = function (entries, onViewError) {
  entries.forEach(entry => {
    let { config, fields } = entry.meta

    // Create Supabase client
    const supabase = createClient(config.project_url, config.secret_api_key);

    // Upload file using standard upload
    (async () => {
      const { data, error } = await supabase.storage
        .from(fields.bucket)
        .upload(fields.path, entry.file)

      if (error) {
        // Handle error
        entry.error()
      } else {
        // Handle success
        entry.progress(100)
      }
    })()
  })
}

export default Uploaders;
