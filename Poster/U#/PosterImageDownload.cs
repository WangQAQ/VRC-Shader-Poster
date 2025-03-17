
using UdonSharp;
using UnityEngine;
using VRC.SDK3.Image;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common.Interfaces;

namespace WangQAQ.UdonPlug
{
	public class PosterImageDownload : UdonSharpBehaviour
	{
		[Tooltip("图片链接")]
		[SerializeField] private VRCUrl url;

		[Space(10)]
		[Tooltip("图像设置")]
		[SerializeField] private Renderer _targetRenderer;

		private VRCImageDownloader _downloader;
		private IVRCImageDownload _imageContext;

		public void Start()
		{
			if (url == null)
				return;

			var scoreMaterial = _targetRenderer.materials;
			var copyMaterial = scoreMaterial[0];
			copyMaterial.name = copyMaterial.name + " for " + gameObject.name;

			_targetRenderer.materials = new Material[] { copyMaterial };

			var rgbInfo = new TextureInfo();
			rgbInfo.GenerateMipMaps = true;

			_downloader = new VRCImageDownloader();
			_downloader.DownloadImage(
				url,
				copyMaterial,
				(IUdonEventReceiver)this,
				rgbInfo);

		}

		public override void OnImageLoadSuccess(IVRCImageDownload result)
		{
			_imageContext = result;
		}
	}
}
