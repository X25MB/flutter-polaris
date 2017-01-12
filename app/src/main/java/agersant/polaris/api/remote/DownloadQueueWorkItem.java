package agersant.polaris.api.remote;

import android.media.MediaDataSource;
import android.os.AsyncTask;

import java.io.File;
import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.MediaPlayerService;
import agersant.polaris.PolarisApplication;

/**
 * Created by agersant on 1/11/2017.
 */

class DownloadQueueWorkItem {

	private File tempFile;
	private CollectionItem item;
	private DownloadTask job;
	private StreamingMediaDataSource mediaDataSource;

	DownloadQueueWorkItem(File file) {
		tempFile = file;
	}

	boolean isHandling(CollectionItem item) {
		return this.item != null && this.item.getPath().equals(item.getPath());
	}

	boolean isIdle() {
		if (job == null) {
			return true;
		}
		AsyncTask.Status status = job.getStatus();
		switch (status) {
			case PENDING:
			case RUNNING:
				return false;
			case FINISHED: {
				PolarisApplication application = PolarisApplication.getInstance();
				MediaPlayerService playerService = application.getMediaPlayerService();
				return !playerService.isUsing(mediaDataSource);
			}
		}
		return true;
	}

	MediaDataSource getMediaDataSource() {
		return mediaDataSource;
	}

	void beginDownload(CollectionItem item) throws IOException {

		String path = item.getPath();
		if (job != null) {
			String currentJobPath = job.getPath();
			if (currentJobPath.equals(path)) {
				return;
			}
			job.cancel(false);
		}

		if (mediaDataSource != null) {
			mediaDataSource.close();
			mediaDataSource = null;
		}

		if (tempFile.exists()) {
			if (!tempFile.delete()) {
				System.out.println("Could not delete streaming file");
			}
		}

		if (!tempFile.createNewFile()) {
			System.out.println("Could not create streaming file");
		}

		mediaDataSource = new StreamingMediaDataSource(tempFile);
		job = new DownloadTask(item, tempFile, mediaDataSource);
		this.item = item;

		job.execute();
	}

}
