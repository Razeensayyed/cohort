package com.cohort.launcher;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import java.util.List;

public class AppAdapter extends RecyclerView.Adapter<AppAdapter.VH> {

    public interface OnAppFocused { void onFocus(AppInfo app, View tile); }
    public interface OnAppClicked { void onClick(AppInfo app); }

    private final Context ctx;
    private final List<AppInfo> apps;
    private OnAppFocused focusListener;
    private OnAppClicked clickListener;
    private int focusedPos = -1;
    private final boolean showLabel;

    public AppAdapter(Context ctx, List<AppInfo> apps, boolean showLabel) {
        this.ctx = ctx;
        this.apps = apps;
        this.showLabel = showLabel;
    }

    public void setOnAppFocused(OnAppFocused l) { focusListener = l; }
    public void setOnAppClicked(OnAppClicked l)  { clickListener = l; }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(ctx).inflate(R.layout.item_app, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        AppInfo app = apps.get(pos);

        Drawable img = app.banner != null ? app.banner : app.icon;
        h.image.setImageDrawable(img);
        h.label.setText(app.label);
        h.label.setVisibility(showLabel ? View.VISIBLE : View.GONE);

        h.root.setOnFocusChangeListener((v, hasFocus) -> {
            if (hasFocus) {
                focusedPos = h.getAdapterPosition();
                if (focusListener != null) focusListener.onFocus(app, v);
            }
        });

        h.root.setOnClickListener(v -> {
            if (clickListener != null) clickListener.onClick(app);
        });
    }

    @Override
    public int getItemCount() { return apps.size(); }

    public int getFocusedPos() { return focusedPos; }

    static class VH extends RecyclerView.ViewHolder {
        final View root;
        final ImageView image;
        final TextView label;
        VH(View v) {
            super(v);
            root  = v.findViewById(R.id.tile_root);
            image = v.findViewById(R.id.iv_banner);
            label = v.findViewById(R.id.tv_label);
        }
    }
}
