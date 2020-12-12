images=(`helm template . | yq -r '..|.image? | select(.)' | sort | uniq`)

for image in ${images[@]};
do
  save_image=$(echo $image | rev | cut -d'/' -f1 | rev | tr ':' '_')
  docker pull ${image}
  #docker save ${image} | gzip > ${save_image}.tar.gz
  docker save ${image} > ${save_image}.tar
done
